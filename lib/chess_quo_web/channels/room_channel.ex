defmodule ChessQuoWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:" <> lobby_code, params, socket) do
    %{
      "current_game_role" => role,
      "current_game_secret" => secret
    } = params["params"]

    role = role_from_string(role)

    # Make sure the lobby exists and the secret is valid
    with {:ok, true} <- ChessQuo.Lobby.lobby_exists?(lobby_code),
         {:ok, true} <- ChessQuo.Lobby.is_valid_secret?(lobby_code, role, secret) do
      # Assign the role and lobby code to the socket
      socket =
        socket
        |> assign(:role, role)
        |> assign(:lobby_code, lobby_code)

      {:ok, socket}
    else
      {:ok, false} ->
        {:error, %{reason: "lobby_not_found"}}

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end

  def handle_in("get_game_state", _, socket) do
    lobby_code = socket.assigns[:lobby_code]

    # Get the game state
    case ChessQuo.Lobby.get_game(lobby_code) do
      {:ok, game} ->
        {:reply, {:ok, Poison.encode!(game)}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("get_valid_moves", params, socket) do
    lobby_code = socket.assigns[:lobby_code]
    board_index = params["board_index"]

    with true <- is_valid_board_index?(board_index),
         {:ok, game} <- ChessQuo.Lobby.get_game(lobby_code) do
      valid_moves = ChessQuo.Chess.MoveFinder.find_valid_moves(game)
      piece_moves = Enum.filter(valid_moves, fn move -> move.from == board_index end)

      # Encode the piece moves to JSON
      piece_moves_json = Enum.map(piece_moves, &Poison.encode!/1)

      {:reply, {:ok, piece_moves_json}, socket}
    else
      false ->
        {:reply, {:error, %{reason: "invalid_board_index"}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("make_move", params, socket) do
    lobby_code = socket.assigns[:lobby_code]
    role = socket.assigns[:role]
    from = params["from"]
    to = params["to"]
    promote_to = params["promote_to"] || nil

    promote_to =
      if promote_to != nil do
        String.to_existing_atom(promote_to)
      else
        nil
      end

    with true <- is_valid_board_index?(from),
         true <- is_valid_board_index?(to),
         {:ok, game} <- ChessQuo.Lobby.get_game(lobby_code),
         {:ok, color} <- ChessQuo.Lobby.get_color(lobby_code, role),
         :ok <- ensure_player_turn(game, color) do
      process_move(game, from, to, promote_to, color, lobby_code, socket)
    else
      false ->
        {:reply, {:error, %{reason: "invalid_board_index"}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  defp process_move(game, from, to, promote_to, color, lobby_code, socket) do
    valid_moves = ChessQuo.Chess.MoveFinder.find_valid_moves(game)

    case find_move(valid_moves, color, from, to, promote_to) do
      {:ok, move} ->
        apply_and_broadcast_move(game, move, color, lobby_code, socket)

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  defp find_move(valid_moves, color, from, to, promote_to) do
    case Enum.find(valid_moves, fn move ->
           move.from == from and move.to == to and move.promote_to == promote_to and
             move.piece.color == color
         end) do
      nil ->
        {:error, "invalid_move"}

      move ->
        {:ok, move}
    end
  end

  defp ensure_player_turn(game, color) do
    if game.turn == color do
      :ok
    else
      {:error, "not_your_turn"}
    end
  end

  defp apply_and_broadcast_move(game, move, color, lobby_code, socket) do
    new_game = ChessQuo.Chess.Game.apply_move(game, move)

    case ChessQuo.Lobby.save_game(lobby_code, new_game) do
      {:ok, _} ->
        broadcast!(socket, "game_state_updated", %{game: Poison.encode!(new_game)})

        # Check the game condition
        game_condition = ChessQuo.Chess.MoveFinder.game_condition(new_game)

        case game_condition do
          :checkmate ->
            player_color_uc = String.capitalize(Atom.to_string(color))
            broadcast!(socket, "game_over", %{reason: "#{player_color_uc} checkmated!"})

          :stalemate ->
            broadcast!(socket, "game_over", %{reason: "Draw"})

          _ ->
            nil
        end

        {:reply, {:ok, Poison.encode!(new_game)}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  defp role_from_string("host"), do: :host
  defp role_from_string(_), do: :guest

  defp is_valid_board_index?(board_index) do
    board_index in 0..63
  end
end

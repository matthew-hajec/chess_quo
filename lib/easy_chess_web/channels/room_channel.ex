defmodule EasyChessWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:" <> lobby_code, params, socket) do
    %{
      "current_game_role" => role,
      "current_game_secret" => secret
    } = params["params"]

    role = role_from_string(role)

    cond do
      !EasyChess.Lobby.lobby_exists?(lobby_code) ->
        {:error, %{reason: "lobby_not_found"}}

      !EasyChess.Lobby.is_valid_secret?(lobby_code, role, secret) ->
        {:error, %{reason: "unauthorized"}}

      true ->
        # Assign the role and lobby code to the socket
        socket =
          socket
          |> assign(:role, role)
          |> assign(:lobby_code, lobby_code)

        {:ok, socket}
    end
  end

  def handle_in("get_game_state", _, socket) do
    lobby_code = socket.assigns[:lobby_code]

    {:ok, game} = EasyChess.Chess.GamesManager.get_game(lobby_code)

    # Encode the game state to JSON
    game_json = Poison.encode!(game)

    {:reply, {:ok, game_json}, socket}
  end

  def handle_in("get_valid_moves", params, socket) do
    lobby_code = socket.assigns[:lobby_code]
    board_index = params["board_index"]

    with true <- is_valid_board_index?(board_index) do
      {:ok, game} = EasyChess.Chess.GamesManager.get_game(lobby_code)
      valid_moves = EasyChess.Chess.MoveFinder.find_valid_moves(game)
      piece_moves = Enum.filter(valid_moves, fn move -> move.from == board_index end)

      # Encode the piece moves to JSON
      piece_moves_json = Enum.map(piece_moves, &Poison.encode!/1)

      {:reply, {:ok, piece_moves_json}, socket}
    else
      false ->
        {:reply, {:error, %{reason: "invalid_board_index"}}, socket}
    end
  end

  def handle_in("make_move", params, socket) do
    lobby_code = socket.assigns[:lobby_code]
    role = socket.assigns[:role]
    from = params["from"]
    to = params["to"]

    # Get the game state
    {:ok, game} = EasyChess.Chess.GamesManager.get_game(lobby_code)

    # Get the host color
    {:ok, host_color} = EasyChess.Lobby.get_host_color(lobby_code)

    # Get the color of the player making the move
    player_color = if role == :host, do: host_color, else: opposite_color(host_color)

    # Get the piece at the from index
    piece = EasyChess.Chess.Game.at(game, from)

    # Ensure the piece is the correct color
    is_correct_color = Atom.to_string(piece.color) == player_color

    # Current turn
    is_turn = Atom.to_string(game.turn) == player_color

    # Make sure the move is in the list of valid moves
    valid_moves = EasyChess.Chess.MoveFinder.find_valid_moves(game)
    move = Enum.find(valid_moves, fn move -> move.from == from and move.to == to end)



    if is_turn and is_correct_color and move != nil do
      # Apply the move
      new_game = EasyChess.Chess.Game.apply_move(game, move)

      # Save the new game state
      EasyChess.Chess.GamesManager.save_game(lobby_code, new_game)

      # Broadcast the new game state
      broadcast!(socket, "game_state", %{game: Poison.encode!(new_game)})

      # Check the game condition
      game_condition = EasyChess.Chess.MoveFinder.game_condition(new_game)

      case game_condition do
        :checkmate ->
          broadcast!(socket, "game_over", %{winner: player_color})

        :stalemate ->
          broadcast!(socket, "game_over", %{winner: "draw"})

        _ ->
          nil
      end

      {:reply, {:ok, Poison.encode!(new_game)}, socket}
    else
      {:reply, {:error, %{reason: "invalid_move"}}, socket}
    end
  end

  defp opposite_color("white"), do: "black"
  defp opposite_color("black"), do: "white"

  defp role_from_string("host"), do: :host
  defp role_from_string(_), do: :guest

  defp is_valid_board_index?(board_index) do
    board_index in 0..63
  end
end

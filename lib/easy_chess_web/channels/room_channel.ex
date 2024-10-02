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

    IO.inspect("Lobby code: #{lobby_code}")

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

  defp role_from_string("host"), do: :host
  defp role_from_string(_), do: :guest

  defp is_valid_board_index?(board_index) do
    board_index in 0..63
  end
end

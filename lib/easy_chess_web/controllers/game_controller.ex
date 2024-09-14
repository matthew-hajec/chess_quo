defmodule EasyChessWeb.GameController do
  use EasyChessWeb, :controller

  def get_game(conn, params) do
    code = params["code"]
    secret = conn.cookies["current_game_secret"]
    role = role_from_string(conn.cookies["current_game_role"])

    cond do
      !EasyChess.Lobby.lobby_exists?(code) ->
        conn
        |> put_flash(:error, "No lobby exists with the given code.")
        |> redirect(to: "/")

      !EasyChess.Lobby.is_valid_secret?(code, role, secret) ->
        conn
        |> put_flash(:error, "Invalid game secret.")
        |> redirect(to: "/")
      true ->
        # Load the game state
        {:ok, game} = EasyChess.Chess.GamesManager.get_game_state(code)

        IO.inspect(game)

        conn
        |> assign(:role, role)
        |> assign(:game, game)
        |> render(:game)
    end
  end


  def role_from_string("host"), do: :host
  def role_from_string(_), do: :guest
end

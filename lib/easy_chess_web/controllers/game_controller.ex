defmodule EasyChessWeb.GameController do
  use EasyChessWeb, :controller

  def get_game(conn, params) do
    code = params["code"]
    secret = conn.cookies["current_game_secret"]

    role =
      if conn.cookies["current_game_role"] == "host" do
        :host
      else
        :guest
      end

    if !EasyChess.Lobby.lobby_exists?(code) do
      conn
      |> put_flash(:error, "No lobby exists with the given code.")
      |> redirect(to: "/")
    else
      if !EasyChess.Lobby.is_valid_secret?(code, role, secret) do
        conn
        |> put_flash(:error, "Invalid game secret.")
        |> redirect(to: "/")
      else
        render(conn, :game)
      end
    end
  end
end

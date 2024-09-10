defmodule EasyChessWeb.LobbyController do
  use EasyChessWeb, :controller

  def get(conn, _params) do
    render(conn, :new_lobby)
  end

  def post(conn, params) do
    {:ok, code, hs, gs} = EasyChess.Lobby.create_lobby()
    conn
    |> put_resp_cookie("current_game_secret", hs)
    |> put_resp_cookie("current_game_code", code)
    |> put_flash(:info, "Lobby Created")
    |> redirect(to: "/#{code}")
  end
end

defmodule EasyChessWeb.LobbyController do
  use EasyChessWeb, :controller

  def get_create_lobby(conn, _params) do
    render(conn, :new_lobby)
  end

  def post_create_lobby(conn, params) do
    password = params["lobby_password"]

    # TODO: Add error handling for lobby creation failure
    {:ok, code, hs, _gs} = EasyChess.Lobby.create_lobby(password)

    conn
    |> put_resp_cookie("current_game_secret", hs)
    |> put_resp_cookie("current_game_code", code)
    |> put_resp_cookie("current_game_role", "host")
    |> put_flash(:info, "Lobby Created")
    |> redirect(to: "/#{code}")
  end

  def get_join_lobby(conn, _params) do
    code = conn.params["code"]

    if !EasyChess.Lobby.lobby_exists?(code) do
      conn
      |> put_flash(:error, "No lobby exists with the given code.")
      |> redirect(to: "/")
    end

    render(conn, :join_lobby)
  end

  def post_join_lobby(conn, params) do
    # Extract parameters
    code = params["code"]
    password = params["lobby_password"]

    case EasyChess.Lobby.compare_password(code, password) do
      true ->
        {:ok, _hs, gs} = EasyChess.Lobby.get_lobby_secrets(code)

        conn
        |> put_resp_cookie("current_game_secret", gs)
        |> put_resp_cookie("current_game_code", code)
        |> put_resp_cookie("current_game_role", "guest")
        |> put_flash(:info, "Lobby Joined")
        |> redirect(to: "/#{code}")

      false ->
        conn
        |> put_flash(:error, "Invalid Password")
        |> redirect(to: "/lobby/join/#{code}")
    end
  end
end

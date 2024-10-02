defmodule EasyChessWeb.LobbyController do
  use EasyChessWeb, :controller

  def help_set_game_cookies(conn, role, code, secret, color) do
    conn
    |> put_resp_cookie("current_game_secret", secret, http_only: false)
    |> put_resp_cookie("current_game_code", code, http_only: false)
    |> put_resp_cookie("current_game_role", role, http_only: false)
    |> put_resp_cookie("current_game_color", color, http_only: false)
  end

  def get_create_lobby(conn, _params) do
    render(conn, :new_lobby)
  end

  def post_create_lobby(conn, params) do
    # TODO: Validate inputs
    password = params["lobby_password"]
    host_color = params["host_color"]

    # TODO: Add error handling for lobby creation failure
    {:ok, code, hs, _gs} = EasyChess.Lobby.create_lobby(password, host_color)

    conn
    |> help_set_game_cookies("host", code, hs, host_color)
    |> put_flash(:info, "Lobby Created")
    |> redirect(to: "/play/#{code}")
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
        {:ok, host_color} = EasyChess.Lobby.get_host_color(code)

        guest_color = if host_color == "white", do: "black", else: "white"

        conn
        |> help_set_game_cookies("guest", code, gs, guest_color)
        |> put_flash(:info, "Lobby Joined")
        |> redirect(to: "/play/#{code}")

      false ->
        conn
        |> put_flash(:error, "Invalid Password")
        |> redirect(to: "/lobby/join/#{code}")
    end
  end
end

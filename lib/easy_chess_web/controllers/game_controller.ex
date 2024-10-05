defmodule EasyChessWeb.GameController do
  use EasyChessWeb, :controller

  def get_game(conn, params) do
    code = params["code"]
    secret = conn.cookies["current_game_secret"]
    # Role is not verified, so it CAN NOT be trusted
    role = role_from_string(conn.cookies["current_game_role"])

    cond do
      !EasyChess.Lobby.lobby_exists?(code) ->
        conn
        |> put_flash(:error, "No lobby exists with the given code.")
        |> put_status(404)
        |> redirect(to: "/")

      !EasyChess.Lobby.is_valid_secret?(code, role, secret) ->
        conn
        |> put_flash(:error, "Invalid game secret.")
        |> put_status(403)
        |> redirect(to: "/")

      true ->
        case EasyChess.Chess.GamesManager.get_game(code) do
          {:error, _} ->
            conn
            |> put_flash(:error, "Error loading game state.")
            |> put_status(500)
            |> redirect(to: "/")

          {:ok, game} ->
            conn
            |> assign(:role, role)
            |> assign(:game, game)
            |> render(:game)
        end
    end
  end

  def role_from_string("host"), do: :host
  def role_from_string(_), do: :guest
end

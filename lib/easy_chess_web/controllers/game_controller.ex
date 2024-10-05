defmodule EasyChessWeb.GameController do
  use EasyChessWeb, :controller

  @get_game_params_schema %{
    code: [type: :string, min_length: 8, max_length: 8]
  }

  def get_game(conn, params) do
    case Tarams.cast(params, @get_game_params_schema) do
      {:ok, _} -> handle_get_game(conn, params)

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid game code.")
        |> redirect(to: "/")
    end
  end

  def handle_get_game(conn, params) do
    IO.inspect(params)
    code = params["code"]
    secret = conn.cookies["current_game_secret"]
    # Role is not verified, so it CAN NOT be trusted
    role = role_from_string(conn.cookies["current_game_role"])

    cond do
      !EasyChess.Lobby.lobby_exists?(code) ->
        IO.puts("No lobby exists with the given code.")
        IO.inspect(code)
        conn
        |> put_flash(:error, "No lobby exists with the given code.")
        |> redirect(to: "/")

      !EasyChess.Lobby.is_valid_secret?(code, role, secret) ->
        conn
        |> put_flash(:error, "Invalid game secret.")
        |> redirect(to: "/")

      true ->
        case EasyChess.Chess.GamesManager.get_game(code) do
          {:error, _} ->
            conn
            |> put_flash(:error, "Error loading game state.")
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

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
    code = params["code"]
    secret = conn.cookies["current_game_secret"]
    # Color and role are not verified, so it CAN NOT be trusted
    # They should only be used for rendering the game page properly
    color = conn.cookies["current_game_color"]
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
        conn
        |> put_layout(false) # Disable the layout
        |> assign(:color, color)
        |> assign(:role, role)
        |> render(:game)
    end
  end

  def role_from_string("host"), do: :host
  def role_from_string(_), do: :guest
end

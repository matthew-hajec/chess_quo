defmodule ChessQuoWeb.GameController do
  require Logger
  use ChessQuoWeb, :controller

  @get_game_params_schema %{
    code: [type: :string, min_length: 8, max_length: 8]
  }

  def get_game(conn, params) do
    case Tarams.cast(params, @get_game_params_schema) do
      {:ok, _} ->
        handle_get_game(conn, params)

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

    with {:ok, true} <- ChessQuo.Lobby.lobby_exists?(code),
         {:ok, true} <- ChessQuo.Lobby.is_valid_secret?(code, role, secret) do
      conn
      # Disable the layout
      |> put_layout(false)
      |> assign(:color, color)
      |> assign(:role, role)
      |> render(:game)
    else
      {:ok, false} ->
        conn
        |> redirect(to: "/lobby/join/#{code}")

      {:error, reason} ->
        Logger.error("Failed to get game: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to join game.")
        |> redirect(to: "/")
    end
  end

  def role_from_string("host"), do: :host
  def role_from_string(_), do: :guest
end

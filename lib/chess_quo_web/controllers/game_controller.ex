defmodule ChessQuoWeb.GameController do
  require Logger
  use ChessQuoWeb, :controller

  alias ChessQuo.Lobby, as: Lobby

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
    # Color is NOT verified! It is only used for rendering.
    color = conn.cookies["current_game_color"]
    role = role_from_string(conn.cookies["current_game_role"])

    case Lobby.load(code) do
      {:ok, lobby} ->
        # The user should have the secret which corresponds to their role.
        expected_secret =
          if role == :host do
            lobby.host_secret
          else
            lobby.guest_secret
          end

        # Make sure the user has the proper secret
        if secret != expected_secret do
          conn
          |> redirect(to: "/lobby/join/#{code}")
        else
          conn
          |> put_layout(false)
          |> assign(:color, color)
          |> assign(:role, role)
          |> render(:game)
        end

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "No lobby exists with the given code.")
        |> redirect(to: "/")

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

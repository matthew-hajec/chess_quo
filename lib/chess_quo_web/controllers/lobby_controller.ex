defmodule ChessQuoWeb.LobbyController do
  require Logger
  use ChessQuoWeb, :controller

  alias ChessQuo.Lobby, as: Lobby

  def help_set_game_cookies(conn, role, code, secret, color) do
    color =
      if color == :white do
        "white"
      else
        "black"
      end

    conn
    |> put_resp_cookie("current_game_secret", secret, http_only: false)
    |> put_resp_cookie("current_game_code", code, http_only: false)
    |> put_resp_cookie("current_game_role", role, http_only: false)
    |> put_resp_cookie("current_game_color", color, http_only: false)
  end

  def get_create_lobby(conn, _params) do
    conn
    |> assign(:page_title, "Create Lobby")
    |> render(:new_lobby)
  end

  @post_create_lobby_params_schema %{
    lobby_password: [type: :string, length: [min: 1, max: 100], required: true],
    host_color: [type: :string, format: ~r/^(white|black)$/, required: true]
  }

  def post_create_lobby(conn, params) do
    case Tarams.cast(params, @post_create_lobby_params_schema) do
      {:ok, _} ->
        handle_post_create_lobby(conn, params)

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid parameters")
        |> redirect(to: "/lobby/create")
    end
  end

  defp handle_post_create_lobby(conn, params) do
    password = params["lobby_password"]
    host_color = params["host_color"]

    host_color =
      if host_color == "white" do
        :white
      else
        :black
      end

    with lobby <- Lobby.new(password, host_color),
         :ok <- Lobby.save(lobby) do
      conn
      |> help_set_game_cookies(
        "host",
        lobby.code,
        lobby.host_secret,
        lobby.host_color
      )
      |> redirect(to: "/play/#{lobby.code}")
    else
      {:error, reason} ->
        Logger.error("Error saving lobby: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Error creating lobby.")
        |> redirect(to: "/lobby/create")
    end
  end

  def get_join_lobby(conn, params) do
    code = params["code"]

    case Lobby.load(code) do
      {:ok, _} ->
        conn
        |> assign(:page_title, "Join Lobby")
        |> render(:join_lobby)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "No lobby exists with the given code.")
        |> redirect(to: "/")

      {:error, reason} ->
        Logger.error("Error checking lobby existence: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Error checking lobby existence.")
        |> redirect(to: "/")
    end
  end

  @post_join_lobby_params_schema %{
    code: [type: :string, length: [min: 8, max: 8], required: true],
    lobby_password: [type: :string, length: [min: 1, max: 100], required: true]
  }
  def post_join_lobby(conn, params) do
    case Tarams.cast(params, @post_join_lobby_params_schema) do
      {:ok, _} ->
        handle_post_join_lobby(conn, params)

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid parameters")
        |> redirect(to: "/lobby/join/#{params["code"]}")
    end
  end

  defp handle_post_join_lobby(conn, params) do
    code = params["code"]
    password = params["lobby_password"]

    case Lobby.load(code) do
      {:ok, lobby} ->
        if lobby.guest_joined == true do
          conn
          |> put_flash(:error, "A guest has already joined this lobby from another device.")
          |> redirect(to: "/")
        else
          if lobby.password != password do
            conn
            |> put_flash(:error, "Invalid Password")
            |> redirect(tp: "lobby/join/#{code}")
          else
            # The user can join this lobby
            color = if lobby.host_color == :white, do: :black, else: :white

            conn
            |> help_set_game_cookies("guest", code, lobby.guest_secret, color)
            |> put_flash(:info, "Lobby joined")
            # CHANGEME!
            |> redirect(to: "/play/#{code}")
          end
        end
    end
  end
end

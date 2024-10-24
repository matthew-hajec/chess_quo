defmodule ChessQuoWeb.LobbyController do
  require Logger
  use ChessQuoWeb, :controller

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

    case ChessQuo.Lobby.create_lobby(password, host_color) do
      {:ok, code, hs, _gs} ->
        conn
        |> help_set_game_cookies("host", code, hs, host_color)
        |> redirect(to: "/play/#{code}")

      {:error, reason} ->
        Logger.error("Error creating lobby: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Error creating lobby.")
        |> redirect(to: "/lobby/create")
    end
  end

  def get_join_lobby(conn, params) do
    code = params["code"]

    case ChessQuo.Lobby.lobby_exists?(code) do
      {:ok, true} ->
        conn
        |> assign(:page_title, "Join Lobby")
        |> render(:join_lobby)

      {:ok, false} ->
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

    with {:ok, true} <- ChessQuo.Lobby.correct_password?(code, password),
         :ok <- ChessQuo.Lobby.set_guest_joined(code),
         {:ok, guest_secret} <- ChessQuo.Lobby.get_secret(code, :guest),
         {:ok, guest_color} <- ChessQuo.Lobby.get_color(code, :guest) do
      conn
      |> help_set_game_cookies("guest", code, guest_secret, guest_color)
      |> put_flash(:info, "Lobby Joined")
      |> redirect(to: "/play/#{code}")
    else
      {:ok, false} ->
        conn
        |> put_flash(:error, "Invalid Password")
        |> redirect(to: "/lobby/join/#{code}")

      {:error, :already_joined} ->
        conn
        |> put_flash(:error, "A guest has already joined this lobby from another device.")
        |> redirect(to: "/")

      _ ->
        conn
        |> put_flash(:error, "Error joining lobby")
        |> redirect(to: "/")
    end
  end
end

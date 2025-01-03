defmodule ChessQuoWeb.Router do
  use ChessQuoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ChessQuoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", ChessQuoWeb do
    pipe_through :browser

    # Home Page
    get "/", HomeController, :get
    post "/", HomeController, :post_join_game

    # Lobby creation
    get "/lobby/create", LobbyController, :get_create_lobby
    post "/lobby/create", LobbyController, :post_create_lobby

    # Lobby join
    get "/lobby/join/:code", LobbyController, :get_join_lobby
    post "/lobby/join/:code", LobbyController, :post_join_lobby

    get "/play/:code", GameController, :get_game
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:chess_quo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ChessQuoWeb.Telemetry
    end
  end
end

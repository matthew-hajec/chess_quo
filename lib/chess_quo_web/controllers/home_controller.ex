defmodule ChessQuoWeb.HomeController do
  use ChessQuoWeb, :controller

  def get(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn = assign(conn, :page_title, "Home")
    render(conn, :home)
  end

  def post_join_game(conn, params) do
    conn
    |> redirect(to: "/lobby/join/#{params["lobby_code"]}")
  end
end

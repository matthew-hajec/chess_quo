defmodule EasyChessWeb.HomeController do
  use EasyChessWeb, :controller

  def get(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn = assign(conn, :page_title, "Home")
    render(conn, :home)
  end
end

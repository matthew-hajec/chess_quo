defmodule EasyChessWeb.GameController do
  use EasyChessWeb, :controller

  def get(conn, params) do
    IO.inspect(params)
    render(conn, :game)
  end
end

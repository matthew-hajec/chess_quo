defmodule ChessQuoWeb.ErrorHTMLTest do
  use ChessQuoWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  describe "error pages contain their corresponding reason-prase" do
    test "404 error page contains 'Not Found'" do
      assert String.contains?(
               render_to_string(ChessQuoWeb.ErrorHTML, "404", "html", []),
               "Not Found"
             )
    end

    test "500 error page contains 'Internal Server Error'" do
      assert String.contains?(
               render_to_string(ChessQuoWeb.ErrorHTML, "500", "html", []),
               "Internal Server Error"
             )
    end

    test "400 error page contains 'Bad Request'" do
      assert String.contains?(
               render_to_string(ChessQuoWeb.ErrorHTML, "400", "html", []),
               "Bad Request"
             )
    end
  end
end

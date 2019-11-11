defmodule LiveViewDemoWeb.ConsoleLiveTest do
  use LiveViewDemoWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "sending valid commands" do
    def render_with_valid_command(%{conn: conn}) do
      {:ok, view, _html} = live(conn, "/")
      [html: render_submit(view, "execute", %{"command" => "a = 1 + 2"})]
    end

    setup :render_with_valid_command

    test "command is visible in the console history", %{html: html} do
      assert html =~ "&gt; a = 1 + 2"
    end

    test "command result is displayed", %{html: html} do
      assert html =~ ~r/<div id="output.".*3.*<\/div>/s
    end

    test "binding value is displayed in the Current Variables section", %{html: html} do
      assert html =~ ~r/<h2.*Current Variables<\/h2><ul><li>a: <code.*3<\/code>/s
    end
  end

  describe "sending invalid commands" do
    test "runtime error is informed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = render_submit(view, "execute", %{"command" => "3 / 0"})

      assert html =~ "%ArithmeticError{message: &quot;bad argument in arithmetic expression&quot;}"
    end

    test "memory abuse is informed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = render_submit(view, "execute", %{"command" => "for i <- 1..70_000, do: i"})

      assert html =~ "The command used more memory than allowed"
    end
  end

  test "send a command with invalid modules", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html = render_submit(view, "execute", %{"command" => "File.exists?(Code.get_docs())"})

    assert html =~ "Invalid modules: [:Code, :File]"
  end
end

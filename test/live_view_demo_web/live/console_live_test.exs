defmodule LiveViewDemoWeb.ConsoleLiveTest do
  use LiveViewDemoWeb.ConnCase
  import Phoenix.LiveViewTest

  test "connected mount", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")

    assert html =~ "<h1>Online Elixir Console</h1>"
  end

  test "send a valid command", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html = render_submit(view, "execute", %{"command" => "a = 1 + 2"})

    # Command is visible in the console history
    assert html =~ "&gt; a = 1 + 2"

    # Command result is displayed
    assert html =~ ~r/<div id="output.".*3.*<\/div>/s

    # Binding value is displayed in the Current Variables section
    assert html =~ ~r/<h2.*Current Variables<\/h2><ul><li>a: <code.*3<\/code>/s
  end

  test "send a command that causes an exception", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html = render_submit(view, "execute", %{"command" => "3 / 0"})

    assert html =~ "%ArithmeticError{message: &quot;bad argument in arithmetic expression&quot;}"
  end

  test "send a command that abuses memory", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html = render_submit(view, "execute", %{"command" => "for i <- 1..70_000, do: i"})

    assert html =~ "The command used more memory than allowed"
  end

  test "send a command with invalid modules", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html = render_submit(view, "execute", %{"command" => "File.exists?(Code.get_docs())"})

    assert html =~
             "It is not allowed to use some Elixir modules. " <>
               "Not allowed modules attempted: [:Code, :File]"
  end
end

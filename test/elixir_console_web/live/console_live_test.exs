defmodule ElixirConsoleWeb.ConsoleLiveTest do
  use ElixirConsoleWeb.ConnCase
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
      assert html =~ ~r/<h2.*Current Variables<\/h2><ul><li.*>a: <code.*3<\/code>/s
    end
  end

  describe "sending invalid commands" do
    test "runtime error is informed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = render_submit(view, "execute", %{"command" => "3 / 0"})

      assert html =~
               "%ArithmeticError{message: &quot;bad argument in arithmetic expression&quot;}"
    end

    test "memory abuse is informed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = render_submit(view, "execute", %{"command" => "for i <- 1..70_000, do: i"})

      assert html =~ "The command used more memory than allowed"
    end

    test "unknown module and functions error is displayed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = render_submit(view, "execute", %{"command" => "Enum.foo(3)"})

      assert html =~
               "%UndefinedFunctionError{arity: 1, function: :foo, message: nil, module: Enum, reason: nil}"
    end

    test "send a command with invalid modules", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = render_submit(view, "execute", %{"command" => "File.exists?(Code.get_docs())"})

      assert html =~
               "It is not allowed to use some Elixir modules. " <>
                 "Not allowed modules attempted: [:Code, :File]"
    end
  end

  describe "autocomplete" do
    test "show suggestions if more than one", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = render_keydown(view, "suggest", %{"keyCode" => 9, "value" => "Enum.co"})

      assert html =~ ~r/Suggestions\:.*Enum\.concat.*Enum\.count/
    end

    test "autocomplete and do not show suggestions if only one", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html = render_keydown(view, "suggest", %{"keyCode" => 9, "value" => "Enum.conc"})

      assert html =~ ~r/\<input .* data-input_value\="Enum.concat"/

      refute html =~ ~r/Suggestions\:.*Enum\.concat/
      assert html =~ "INSTRUCTIONS"
    end
  end
end

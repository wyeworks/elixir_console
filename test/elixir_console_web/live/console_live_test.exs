defmodule ElixirConsoleWeb.ConsoleLiveTest do
  use ElixirConsoleWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "sending valid commands" do
    def render_with_valid_command(%{conn: conn}) do
      {:ok, view, _html} = live(conn, "/")
      render_submit([view, "command_input"], "execute", %{"command" => "a = 1 + 2"})

      [html: render(view)]
    end

    setup :render_with_valid_command

    test "command is visible in the console history", %{html: html} do
      assert html =~ ~r/&gt; a = 1 <span [\S \n]*>\+<\/span> 2/
    end

    test "command result is displayed", %{html: html} do
      assert html =~ ~r/<div id="output.".*3.*<\/div>/s
    end

    test "binding value is displayed in the Current Variables section", %{html: html} do
      assert html =~ ~r/<h2.*Current Bindings<\/h2><ul><li.*>a: <code.*3<\/code>/s
    end
  end

  describe "sending invalid commands" do
    test "runtime error is informed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      _ = render_submit([view, "command_input"], "execute", %{"command" => "3 / 0"})
      html = render(view)

      assert html =~
               "%ArithmeticError{message: &quot;bad argument in arithmetic expression&quot;}"
    end

    test "memory abuse is informed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      _ =
        render_submit([view, "command_input"], "execute", %{
          "command" => "for i <- 1..70_000, do: i"
        })

      html = render(view)

      assert html =~ "The command used more memory than allowed"
    end

    test "unknown module and functions error is displayed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      _ = render_submit([view, "command_input"], "execute", %{"command" => "Enum.foo(3)"})
      html = render(view)

      assert html =~
               "%UndefinedFunctionError{arity: 1, function: :foo, message: nil, module: Enum, reason: nil}"
    end

    test "send a command with invalid modules", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      _ =
        render_submit([view, "command_input"], "execute", %{
          "command" => "File.exists?(Code.get_docs())"
        })

      html = render(view)

      assert html =~
               "Some Elixir modules are not allowed to be used. " <>
                 "Not allowed modules attempted: [:Code, :File]"
    end
  end

  describe "autocomplete" do
    test "show suggestions if more than one", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      _ = render_hook([view, "command_input"], :"caret-position", %{"position" => 7})

      _ =
        render_keydown([view, "command_input"], "suggest", %{"keyCode" => 9, "value" => "Enum.co"})

      html = render(view)

      assert html =~ ~r/Suggestions\:.*Enum\.concat.*Enum\.count/
    end

    test "autocomplete and do not show suggestions if only one", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      _ = render_hook([view, "command_input"], :"caret-position", %{"position" => 9})

      _ =
        render_keydown([view, "command_input"], "suggest", %{
          "keyCode" => 9,
          "value" => "Enum.conc"
        })

      html = render(view)

      assert html =~ ~r/\<input .* data-input_value\="Enum.concat"/

      refute html =~ ~r/Suggestions\:.*Enum\.concat/
      assert html =~ "INSTRUCTIONS"
    end

    test "show suggestions considering caret position in the command input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      _ = render_hook([view, "command_input"], :"caret-position", %{"position" => 7})

      _ =
        render_keydown([view, "command_input"], "suggest", %{
          "keyCode" => 9,
          "value" => "Enum.co([1,2]) - 2"
        })

      html = render(view)

      assert html =~ ~r/Suggestions\:.*Enum\.concat.*Enum\.count/
    end

    test "autocomplete considering caret position in the command input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      _ = render_hook([view, "command_input"], :"caret-position", %{"position" => 9})

      html =
        render_keydown([view, "command_input"], "suggest", %{
          "keyCode" => 9,
          "value" => "Enum.conc([1,2], [3])"
        })

      assert html =~ ~r/\<input .* data-input_value\="Enum.concat\(\[1,2\], \[3\]\)"/
      assert html =~ ~r/\<input .* data-caret_position\="11"/

      refute html =~ ~r/Suggestions\:.*Enum\.concat/
      assert html =~ "INSTRUCTIONS"
    end
  end
end

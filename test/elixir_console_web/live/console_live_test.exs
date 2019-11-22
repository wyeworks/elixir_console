defmodule ElixirConsoleWeb.ConsoleLiveTest do
  use ElixirConsoleWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  # Code based on https://github.com/phoenixframework/phoenix_live_view/blob/bba042ed6a6efa45f56b30c4d26fda7a0bdb8991/lib/phoenix_live_view/test/live_view_test.ex#L459
  # because LiveViewTest module does not have a public "render_hook" function yet.
  # Let's remove this when this method is available.
  alias Phoenix.LiveViewTest.View

  def render_event([%View{} = view | path], type, event, value) do
    case GenServer.call(
           proxy_pid(view),
           {:render_event, proxy_topic(view), type, path, event, value}
         ) do
      {:ok, html} -> html
      {:error, reason} -> {:error, reason}
    end
  end

  defp proxy_pid(%View{proxy: {_ref, _topic, pid}}), do: pid
  defp proxy_topic(%View{proxy: {_ref, topic, _pid}}), do: topic

  describe "sending valid commands" do
    def render_with_valid_command(%{conn: conn}) do
      {:ok, view, _html} = live(conn, "/")
      [html: render_submit(view, "execute", %{"command" => "a = 1 + 2"})]
    end

    setup :render_with_valid_command

    test "command is visible in the console history", %{html: html} do
      assert html =~ ~r/&gt; a = 1 <span [\S \n]*>\+<\/span> 2/
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
      _ = render_event([view], :hook, :"caret-position", %{"position" => 7})
      html = render_keydown(view, "suggest", %{"keyCode" => 9, "value" => "Enum.co"})

      assert html =~ ~r/Suggestions\:.*Enum\.concat.*Enum\.count/
    end

    test "autocomplete and do not show suggestions if only one", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      _ = render_event([view], :hook, :"caret-position", %{"position" => 9})
      html = render_keydown(view, "suggest", %{"keyCode" => 9, "value" => "Enum.conc"})

      assert html =~ ~r/\<input .* data-input_value\="Enum.concat"/

      refute html =~ ~r/Suggestions\:.*Enum\.concat/
      assert html =~ "INSTRUCTIONS"
    end

    test "show suggestions considering caret position in the command input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      _ = render_event([view], :hook, :"caret-position", %{"position" => 7})
      html = render_keydown(view, "suggest", %{"keyCode" => 9, "value" => "Enum.co([1,2]) - 2"})

      assert html =~ ~r/Suggestions\:.*Enum\.concat.*Enum\.count/
    end

    test "autocomplete considering caret position in the command input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      _ = render_event([view], :hook, :"caret-position", %{"position" => 9})

      html =
        render_keydown(view, "suggest", %{"keyCode" => 9, "value" => "Enum.conc([1,2], [3])"})

      assert html =~ ~r/\<input .* data-input_value\="Enum.concat\(\[1,2\], \[3\]\)"/
      assert html =~ ~r/\<input .* data-caret_position\="11"/

      refute html =~ ~r/Suggestions\:.*Enum\.concat/
      assert html =~ "INSTRUCTIONS"
    end
  end
end

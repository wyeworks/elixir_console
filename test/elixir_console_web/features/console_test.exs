defmodule ElixirConsoleWeb.ConsoleTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Wallaby.Query, only: [css: 1]

  feature "visitor can try elixir in the console", %{session: session} do
    session
    |> visit("/")
    |> fill_in(css("#commandInput"), with: "a = 1 + 2")
    |> send_keys([:enter])
    |> find(css("#commandOutput"), fn output ->
      assert_text(output, "> a = 1 + 2")
      assert_text(output, "3")
    end)
    |> find(css("#commandInput"), fn input ->
      input
      |> has_value?("")
      |> assert
    end)
  end
end

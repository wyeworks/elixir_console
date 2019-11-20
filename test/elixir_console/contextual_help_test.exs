defmodule ElixirConsole.ContextualHelpTest do
  use ExUnit.Case, async: true
  alias ElixirConsole.ContextualHelp

  test "returns only one element if no Elixir functions are found" do
    assert ContextualHelp.compute("foo(1 + 4)") == ["foo(1 + 4)"]
  end

  test "adds documentation metadata if Elixir function is found" do
    assert [
             "",
             {"Enum.count",
              %{
                docs: _,
                func_name: "Enum.count/1",
                header: ["count(enumerable)"],
                link: "https://hexdocs.pm/elixir/Enum.html#count/1"
              }},
             "([1,2]) + 3"
           ] = ContextualHelp.compute("Enum.count([1,2]) + 3")
  end

  test "adds documentation metadata properly when omitting default parameters" do
    assert [
             "",
             {"Enum.find",
              %{
                docs: _,
                func_name: "Enum.find/3",
                header: ["find(enumerable, default \\\\ nil, fun)"],
                link: "https://hexdocs.pm/elixir/Enum.html#find/3"
              }},
             "([2, 3, 4], fn x -> x == 2 end)"
           ] = ContextualHelp.compute("Enum.find([2, 3, 4], fn x -> x == 2 end)")
  end
end

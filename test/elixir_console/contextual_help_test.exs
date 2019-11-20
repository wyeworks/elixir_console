defmodule ElixirConsole.ContextualHelpTest do
  use ExUnit.Case, async: true
  alias ElixirConsole.ContextualHelp

  test "returns only one element if no Elixir functions are found" do
    assert ContextualHelp.compute("foo(1)") == ["foo(1)"]
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
             "([1,2])"
           ] = ContextualHelp.compute("Enum.count([1,2])")
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
             "([2, 3, 4], fn x -> x end)"
           ] = ContextualHelp.compute("Enum.find([2, 3, 4], fn x -> x end)")
  end

  test "adds documentation metadata to Kernel functions" do
    assert [
             "",
             {"length",
              %{
                docs: _,
                func_name: "Kernel.length/1",
                header: ["length(list)"],
                link: "https://hexdocs.pm/elixir/Kernel.html#length/1"
              }},
             "([1,2,3])"
           ] = ContextualHelp.compute("length([1,2,3])")
  end

  test "adds documentation metadata to Kernel macros" do
    assert [
             "3 ",
             {"||",
              %{
                docs: _,
                func_name: "Kernel.||/2",
                header: ["left || right"],
                link: "https://hexdocs.pm/elixir/Kernel.html#||/2"
              }},
             " 4"
           ] = ContextualHelp.compute("3 || 4")
  end
end

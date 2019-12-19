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
                func_name: "Enum.count/1",
                header: ["count(enumerable)"],
                link: "https://hexdocs.pm/elixir/Enum.html#count/1"
              }},
             "([1,2])"
           ] = ContextualHelp.compute("Enum.count([1,2])")
  end

  test "adds documentation metadata when expression is a list" do
    assert [
             "[",
             {"Enum.count",
              %{
                func_name: "Enum.count/1",
                header: ["count(enumerable)"],
                link: "https://hexdocs.pm/elixir/Enum.html#count/1"
              }},
             "([1,2])]"
           ] = ContextualHelp.compute("[Enum.count([1,2])]")
  end

  test "adds documentation metadata when expression is a map" do
    assert [
             "%{\"a\" => ",
             {"Enum.count",
              %{
                func_name: "Enum.count/1",
                header: ["count(enumerable)"],
                link: "https://hexdocs.pm/elixir/Enum.html#count/1"
              }},
             "([1,2])}"
           ] = ContextualHelp.compute("%{\"a\" => Enum.count([1,2])}")
  end

  test "adds documentation metadata when expression is a keyword list" do
    assert [
             "[a: ",
             {"Enum.count",
              %{
                func_name: "Enum.count/1",
                header: ["count(enumerable)"],
                link: "https://hexdocs.pm/elixir/Enum.html#count/1"
              }},
             "([1,2])]"
           ] = ContextualHelp.compute("[a: Enum.count([1,2])]")
  end

  test "adds documentation metadata properly when omitting default parameters" do
    assert [
             "",
             {"Enum.find",
              %{
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
                func_name: "Kernel.||/2",
                header: ["left || right"],
                link: "https://hexdocs.pm/elixir/Kernel.html#||/2"
              }},
             " 4"
           ] = ContextualHelp.compute("3 || 4")
  end

  test "adds metadata indicating whether is function or operator" do
    assert [
             "5 ",
             {"+",
              %{
                type: :operator
              }},
             " ",
             {"Enum.count",
              %{
                type: :function
              }},
             "([2,4])"
           ] = ContextualHelp.compute("5 + Enum.count([2,4])")
  end

  test "adds metadata also for binary operator with functions in the left side" do
    assert [
             "",
             {"Enum.count",
              %{
                type: :function
              }},
             "([2]) ",
             {"+",
              %{
                type: :operator
              }},
             " 5"
           ] = ContextualHelp.compute("Enum.count([2]) + 5")
  end
end

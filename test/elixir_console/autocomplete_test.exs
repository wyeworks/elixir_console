defmodule ElixirConsole.AutocompleteTest do
  use ExUnit.Case, async: true
  alias ElixirConsole.Autocomplete

  describe "get_suggestions" do
    test "returns no suggestions" do
      assert Autocomplete.get_suggestions("Foo.bar", 8, []) == []
    end

    test "returns no suggestions when the caret is in the middle" do
      assert Autocomplete.get_suggestions("Foo.bar", 4, []) == []
    end

    test "returns suggestions" do
      assert Autocomplete.get_suggestions("Enum.co", 7, []) == ["Enum.concat", "Enum.count"]
    end

    test "returns suggestions when the caret is in the middle" do
      assert Autocomplete.get_suggestions("Enum.ch foo bar", 7, []) == [
               "Enum.chunk_by",
               "Enum.chunk_every",
               "Enum.chunk_while"
             ]
    end

    test "returns suggestions from bindings" do
      assert Autocomplete.get_suggestions("4 + va", 6, var1: 1, var2: 2) == [
               "var1",
               "var2"
             ]
    end

    test "returns suggestions including bindings and Elixir functions" do
      assert Autocomplete.get_suggestions("List", 4, Listado: 1) == [
               "Listado",
               "List.ascii_printable?",
               "List.delete",
               "List.delete_at",
               "List.duplicate",
               "List.first",
               "List.flatten",
               "List.foldl",
               "List.foldr",
               "List.improper?"
             ]
    end
  end

  describe "autocompleted_input" do
    test "returns updated input value and caret position" do
      assert Autocomplete.autocompleted_input("3 + Enum.cou", 12, "Enum.count") == {
               "3 + Enum.count",
               14
             }
    end

    test "returns modifications when it happens in the middle of the input string" do
      assert Autocomplete.autocompleted_input("Enum.cou([1]) + 3", 8, "Enum.count") == {
               "Enum.count([1]) + 3",
               10
             }
    end
  end
end

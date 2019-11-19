defmodule ElixirConsole.AutocompleteTest do
  use ExUnit.Case
  alias ElixirConsole.Autocomplete

  describe "get_suggestions" do
    test "returns no suggestions" do
      assert Autocomplete.get_suggestions("Foo.bar", 8, []) == []
    end

    test "returns no suggestions when the caret is in the middle" do
      assert Autocomplete.get_suggestions("Foo.bar", 4, []) == []
    end

    test "returns suggestions with the caret" do
      assert Autocomplete.get_suggestions("Enum.co", 7, []) == ["Enum.concat", "Enum.count"]
    end

    test "returns suggestions with the caret is in the middle" do
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
end

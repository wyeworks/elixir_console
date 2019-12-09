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

    test "returns suggestions only for the module name" do
      assert Autocomplete.get_suggestions("Li", 3, []) == ["List"]
    end

    test "returns only the module name if this is the last word" do
      assert Autocomplete.get_suggestions("12 + Enum", 9, []) == ["Enum", "Enumerable"]
    end

    test "returns functions names when the last word includes module name and period" do
      assert Autocomplete.get_suggestions("12 + List.", 10, []) == [
               "List.ascii_printable?",
               "List.delete",
               "List.delete_at",
               "List.duplicate",
               "List.first",
               "List.flatten",
               "List.foldl",
               "List.foldr",
               "List.improper?",
               "List.insert_at"
             ]
    end

    test "returns suggestions from bindings" do
      assert Autocomplete.get_suggestions("4 + varia", 9, variable1: 1, variable2: 2) == [
               "variable1",
               "variable2"
             ]
    end

    test "returns suggestions from Kernel functions" do
      assert Autocomplete.get_suggestions("4 + le", 6, []) == ["length"]
    end

    test "does not return unsafe functions into the suggestions" do
      assert Autocomplete.get_suggestions("spawn", 5, []) == []
    end

    test "does not return unsafe modules into the suggestions" do
      assert Autocomplete.get_suggestions("Cod", 3, []) == []
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

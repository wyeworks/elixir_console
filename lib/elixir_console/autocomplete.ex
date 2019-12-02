defmodule ElixirConsole.Autocomplete do
  @moduledoc """
  Encapsulates all the logic related with the autocomplete feature
  """

  alias ElixirConsole.Documentation

  @max_command_length 10_000

  @doc """
  Get a list of suggestions with all the possible words that could fit in the
  command that is being typed by the user.
  """
  def get_suggestions(value, caret_position, bindings) do
    word_to_autocomplete = word_to_autocomplete(value, caret_position)
    modules_or_functions = modules_or_functions_from_docs(word_to_autocomplete)

    bindings
    |> all_suggestions_candidates(modules_or_functions)
    |> filter_suggestions(word_to_autocomplete)
  end

  defp all_suggestions_candidates(bindings, modules_or_functions) do
    bindings_variable_names(bindings) ++ elixir_library_names(modules_or_functions)
  end

  defp bindings_variable_names(bindings) do
    bindings
    |> Enum.map(fn {name, _} -> Atom.to_string(name) end)
    |> Enum.sort()
  end

  defp modules_or_functions_from_docs(word_to_autocomplete) do
    cond do
      String.match?(word_to_autocomplete, ~r/^[A-Z]\w*\.\w*$/) ->
        :functions

      String.match?(word_to_autocomplete, ~r/^[a-z]/) ->
        :kernel_functions

      true ->
        :modules
    end
  end

  defp elixir_library_names(modules_or_functions) do
    modules_or_functions
    |> retrieve_names_from_documentation()
    |> Enum.sort()
  end

  defp retrieve_names_from_documentation(:functions), do: Documentation.get_functions_names()

  defp retrieve_names_from_documentation(:kernel_functions),
    do: Documentation.get_kernel_functions_names()

  defp retrieve_names_from_documentation(:modules), do: Documentation.get_modules_names()

  defp filter_suggestions(candidates, word_to_autocomplete) do
    candidates
    |> Enum.filter(&String.starts_with?(&1, word_to_autocomplete))
    |> Enum.take(10)
  end

  @doc """
  Returns a modified version of the command input value with an autocompleted
  word. It means that the `suggestion` value is used to replace the word that
  ends in the `caret_position` position of the provided `value`.

  It returns a tuple with the new input command (modified with the autocompleted
  word) and the new caret position (right after the last character of the
  autocompleted word)
  """
  def autocompleted_input(value, caret_position, autocompleted_word) do
    word_to_autocomplete = word_to_autocomplete(value, caret_position)

    {
      calculate_new_input_value(value, caret_position, word_to_autocomplete, autocompleted_word),
      calculate_new_caret_position(caret_position, word_to_autocomplete, autocompleted_word)
    }
  end

  defp word_to_autocomplete(value, caret_position) do
    {value_until_caret, _} = split_command_for_autocomplete(value, caret_position)
    value_until_caret |> String.split() |> List.last() || ""
  end

  defp split_command_for_autocomplete(value, caret_position) do
    {String.slice(value, 0, caret_position),
     String.slice(value, caret_position, @max_command_length)}
  end

  defp calculate_new_caret_position(caret_position, word_to_autocomplete, autocompleted_word) do
    String.length(autocompleted_word) - String.length(word_to_autocomplete) + caret_position
  end

  defp calculate_new_input_value(
         input_value,
         caret_position,
         word_to_autocomplete,
         autocompleted_word
       ) do
    {value_until_caret, value_from_caret} =
      split_command_for_autocomplete(input_value, caret_position)

    Regex.replace(~r/\.*#{word_to_autocomplete}$/, value_until_caret, autocompleted_word) <>
      value_from_caret
  end
end

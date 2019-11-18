defmodule ElixirConsole.Autocomplete do
  @moduledoc """
  Encapsulates all the logic related with the autocomplete feature
  """

  alias ElixirConsole.Documentation

  @doc """
  Get a list of suggestions with all the possible words that could fit in the
  command that is being typed by the user.
  """
  def get_suggestions(value, caret_position, bindings) do
    word_to_autocomplete = word_to_autocomplete(value, caret_position)

    bindings_names = Enum.map(bindings, fn {name, _} -> Atom.to_string(name) end)
    all_names = bindings_names ++ Documentation.get_functions_names()

    all_names
    |> Enum.filter(&String.starts_with?(&1, word_to_autocomplete))
    |> Enum.sort()
    |> Enum.take(10)
  end

  @doc """
  Returns a modified version of the command input value with an autocompleted word.
  It means that the `suggestion` value is used to replace the word that ends in the
  `caret_position` position of the provided `value`
  """
  def autocompleted_input(value, caret_position, suggestion) do
    word_to_autocomplete = word_to_autocomplete(value, caret_position)
    {value_until_caret, value_from_caret} = split_command_for_autocomplete(value, caret_position)

    Regex.replace(~r/\.*#{word_to_autocomplete}$/, value_until_caret, suggestion) <>
      value_from_caret
  end

  defp word_to_autocomplete(value, caret_position) do
    {value_until_caret, _} = split_command_for_autocomplete(value, caret_position)
    value_until_caret |> String.split() |> List.last() || ""
  end

  defp split_command_for_autocomplete(value, caret_position) do
    {String.slice(value, 0, caret_position), String.slice(value, caret_position, 10_000)}
  end
end

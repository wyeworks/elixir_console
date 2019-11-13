defmodule LiveViewDemo.Sandbox.CommandValidator do
  @moduledoc """
  Check if a given Elixir code from untrusted sources is safe to be executed in
  the sandbox. This module also defines a behavior to be implemented by
  validator modules, providing a mechanism to compose individual safety checks
  over the command.
  """

  @type ast :: Macro.t()
  @callback validate(ast()) :: :ok | {:error, String.t()}

  alias LiveViewDemo.Sandbox.{AllowedElixirModules, ErlangModulesAbsence, SafeKernelFunctions}

  @ast_validator_modules [SafeKernelFunctions, AllowedElixirModules, ErlangModulesAbsence]

  def safe_command?(command) do
    {command, words_dict} = normalize_atoms(command)

    ast = Code.string_to_quoted!(command)

    {ast, _} = normalize_ast(ast, words_dict)

    Enum.reduce_while(@ast_validator_modules, nil, fn module, _acc ->
      case apply(module, :validate, [ast]) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  def normalize_atoms(command) do
    known_words = ~w(
      Enum
      count
      concat
      ~w
    )

    words = Regex.scan(~r/[a-zA-Z~][a-zA-Z_\-\?]*/s, command) |> List.flatten()

    words_dict =
      (words -- known_words)
      |> Enum.with_index(1)
      |> Enum.reduce(%{}, fn {word, index}, acc ->
        Map.put(acc, "sandbox#{index}", word)
      end)

    normalized_command = Enum.reduce(words_dict, command, fn {safe_word, original_word}, acc ->
      String.replace(acc, original_word, safe_word)
    end)

    {normalized_command, words_dict}
  end

  def normalize_ast(ast, words_dict) do
    Macro.prewalk(ast, [], &restore_strings(&1, &2, words_dict))
  end

  defp restore_strings(elem, _, words_dict) when is_binary(elem) do
    restored_string = Enum.reduce(words_dict, elem, fn {safe_word, original_word}, acc ->
      String.replace(acc, safe_word, original_word)
    end)
    {restored_string, []}
  end

  defp restore_strings(elem, _, _), do: {elem, []}
end

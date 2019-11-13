defmodule LiveViewDemo.Sandbox.CommandSanitizer do
  def sanitize(command) do
    {command, words_dict} = normalize_atoms(command)
    ast = Code.string_to_quoted!(command)
    {ast, _} = normalize_ast(ast, words_dict)

    %{ast: ast, words_dict: words_dict}
  end

  def normalize_atoms(command) do
    known_words = ~w(
      Kernel
      Enum
      count
      concat
      spawn
      ~w
    )

    parts = Regex.split(~r/[a-zA-Z~][a-zA-Z_\-\?]*/s, command, include_captures: true)

    {normalized_parts, words_dict} =
      parts
      |> Enum.with_index(1)
      |> Enum.reduce({[], %{}}, fn {part, index}, {parts_acc, dict_acc} ->
        cond do
          part in known_words ->
            {[part | parts_acc], dict_acc}
          part =~ ~r/[A-Z][a-zA-Z_\-\?]*/s ->
            dict_acc = Map.put(dict_acc, "Sandbox#{index}", part)
            {["Sandbox#{index}" | parts_acc], dict_acc}
          part =~ ~r/[a-zA-Z~][a-zA-Z_\-\?]*/s ->
            dict_acc = Map.put(dict_acc, "sandbox#{index}", part)
            {["sandbox#{index}" | parts_acc], dict_acc}
          true ->
            {[part | parts_acc], dict_acc}
        end
      end)

    normalized_command = normalized_parts |> Enum.reverse() |> Enum.join()
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

  # Special case to deal with charlist
  defp restore_strings(elem, _, words_dict) when is_list(elem) do
    if :io_lib.char_list(elem) do
      restored_string = Enum.reduce(words_dict, to_string(elem), fn {safe_word, original_word}, acc ->
        String.replace(acc, safe_word, original_word)
      end)
      {to_charlist(restored_string) , []}
    else
      {elem, []}
    end
  end

  defp restore_strings(elem, _, _), do: {elem, []}
end

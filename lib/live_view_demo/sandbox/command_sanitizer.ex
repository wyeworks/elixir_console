defmodule LiveViewDemo.Sandbox.CommandSanitizer do
  def sanitize(command) do
    {command, words_dict} = normalize_atoms(command)

    try do
      ast = Code.string_to_quoted!(command)
      {ast, _} = normalize_ast(ast, words_dict)

      %{ast: ast, words_dict: words_dict}
    rescue
      exception ->
        {:error, restore(inspect(exception), words_dict)}
    end
  end

  def restore(error_string, words_dict) when is_binary(error_string) do
    Enum.reduce(words_dict, error_string, fn {safe_word, original_word}, acc ->
      String.replace(acc, safe_word, original_word)
    end)
  end

  defp normalize_atoms(command) do
    known_words = ~w(
      Kernel
      Enum
      File
      apply
      count
      concat
      cwd
      each
      do
      for
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
            if part in Map.values(dict_acc) do
              sandboxed_word =
                dict_acc
                |> Enum.find(fn {_key, val} -> val == part end)
                |> elem(0)

              {[sandboxed_word | parts_acc], dict_acc}
            else
              dict_acc = Map.put(dict_acc, "Sandbox#{index}", part)
              {["Sandbox#{index}" | parts_acc], dict_acc}
            end
          part =~ ~r/[a-zA-Z~][a-zA-Z_\-\?]*/s ->
            if part in Map.values(dict_acc) do
              sandboxed_word =
                dict_acc
                |> Enum.find(fn {_key, val} -> val == part end)
                |> elem(0)

              {[sandboxed_word | parts_acc], dict_acc}
            else
              dict_acc = Map.put(dict_acc, "sandbox#{index}", part)
              {["sandbox#{index}" | parts_acc], dict_acc}
            end
          true ->
            {[part | parts_acc], dict_acc}
        end
      end)

    normalized_command = normalized_parts |> Enum.reverse() |> Enum.join()
    {normalized_command, words_dict}
  end

  defp normalize_ast(ast, words_dict) do
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

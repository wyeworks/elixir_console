defmodule ElixirConsole.ContextualHelp do
  alias ElixirConsole.Documentation

  def compute(command) do
    case Code.string_to_quoted(command) do
      {:ok, expr} ->
        functions = find_functions(expr, [])
        add_documentation(command, functions)

      _ ->
        [command]
    end
  end

  defp find_functions({{:., _, [{_, _, [module]}, func_name]}, _, params}, acc) do
    acc = acc ++ [%{module: module, func_name: func_name, func_ary: Enum.count(params)}]
    Enum.reduce(params, acc, fn node, acc -> find_functions(node, acc) end)
  end

  defp find_functions({_, _, list}, acc) when is_list(list) do
    Enum.reduce(list, acc, fn node, acc -> find_functions(node, acc) end)
  end

  defp find_functions(_, acc), do: acc

  defp add_documentation(command, []), do: [command]

  defp add_documentation(
         command,
         [%{module: module, func_name: func_name, func_ary: func_ary} | rest]
       ) do
    func_fullname = "#{module}.#{func_name}"
    regex = ~r/#{Regex.escape(func_fullname)}/

    [part_before, _, remaining_command] =
      Regex.split(regex, command, include_captures: true, parts: 2)

    parts_to_add =
      case Documentation.get_doc(%Documentation.Key{func_name: func_fullname, arity: func_ary}) do
        nil ->
          [part_before, func_fullname]

        doc ->
          [part_before, {func_fullname, doc}]
      end

    parts_to_add ++ add_documentation(remaining_command, rest)
  end
end

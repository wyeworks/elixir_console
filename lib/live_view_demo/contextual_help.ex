defmodule LiveViewDemo.ContextualHelp do

  def compute(command) do
    {:ok, expr} = Code.string_to_quoted(command)
    functions = find_functions(expr, [])
    add_documentation(command, functions)
  end

  defp find_functions({{:., _, [{_, _, [module]}, func_name]}, _, params}, acc) do
    acc = acc ++ [%{module: module, func_name: func_name, func_ary: Enum.count(params)}]
    Enum.reduce(params, acc, fn node, acc -> find_functions(node, acc) end)
  end

  defp find_functions({_, _, list}, acc) when is_list(list) do
    Enum.reduce(list, acc, fn node, acc -> find_functions(node, acc) end)
  end

  defp find_functions(_, acc), do: acc

  defp add_documentation(
        command,
        [%{module: module, func_name: func_name, func_ary: func_ary} | rest]
      ) do
    regex = ~r/#{module}.#{Regex.escape(Atom.to_string(func_name))}/
    [before, _, remaining_command] = Regex.split(regex, command, include_captures: true, parts: 2)

    docs = LiveViewDemo.Documentation.get_doc(%{func_name: "#{module}.#{func_name}", func_ary: func_ary})

    case docs do
      nil ->
        [before, "#{module}.#{func_name}"] ++ add_documentation(remaining_command, rest)

      doc ->
        [before, {"#{module}.#{func_name}", doc}] ++
          add_documentation(remaining_command, rest)
    end
  end

  defp add_documentation(command, []) do
    [command]
  end
end

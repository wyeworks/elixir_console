defmodule ContextualHelp do

  def compute(command) do
    # TODO Enum is harcoded
    docs = docs(Enum)

    {:ok, expr} = Code.string_to_quoted(command)
    functions = find_functions(expr, [])
    add_documentation(command, functions, docs)
  end

  def find_functions({{:., _, [{_, _, [:Enum]}, func_name]}, _, params}, acc) do
    acc = acc ++ [%{func_name: func_name, func_ary: Enum.count(params)}]
    Enum.reduce(params, acc, fn node, acc -> find_functions(node, acc) end)
  end

  def find_functions(_, acc), do: acc

  def add_documentation(command, [%{func_name: func_name, func_ary: func_ary} | rest], docs) do
    regex = ~r/Enum.#{Regex.escape(Atom.to_string(func_name))}/
    [before, _, remaining_command] = Regex.split(regex, command, include_captures: true, parts: 2)

    case docs[%{func_name: "Enum.#{func_name}", func_ary: func_ary}] do
      nil -> [before, "Enum.#{func_name}"] ++ add_documentation(remaining_command, rest, docs)
      doc -> [before, {"Enum.#{func_name}", doc}] ++ add_documentation(remaining_command, rest, docs)
    end
  end

  def add_documentation(command, [], _) do
    [command]
  end

  def docs(module) do
    {:docs_v1, _, :elixir, _, _, _, list} = Code.fetch_docs(module)

    Enum.reduce(list, %{}, fn function, acc ->
      case function do
        {{:function, func_name, func_ary}, _, _header, %{"en" => docs}, _} ->
          {:ok, html_doc, _} = Earmark.as_html(docs)
          Map.put(acc, %{func_name: "Enum.#{func_name}", func_ary: func_ary}, %{header: "Enum.#{func_name}/#{func_ary}", docs: html_doc})
        _ ->
          acc
      end
    end)
  end
end

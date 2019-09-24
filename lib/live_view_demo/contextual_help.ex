defmodule ContextualHelp do
  @modules [
    Access,
    Enum,
    Keyword,
    List,
    Map,
    MapSet,
    Range,
    Stream,
    File,
    IO,
    Path,
    Port,
    StringIO,
    System,
    Calendar,
    Agent,
    Application,
    Config,
    DynamicSupervisor,
    GenEvent,
    Node,
    Process,
    Registry,
    Task,
    Collectable,
    Enumerable,
    Inspect,
    Protocol,
    Code,
    Macro
  ]

  def compute(command) do
    docs = retrive_docs(@modules)

    {:ok, expr} = Code.string_to_quoted(command)
    functions = find_functions(expr, [])
    add_documentation(command, functions, docs)
  end

  def find_functions({{:., _, [{_, _, [module]}, func_name]}, _, params}, acc) do
    acc = acc ++ [%{module: module, func_name: func_name, func_ary: Enum.count(params)}]
    Enum.reduce(params, acc, fn node, acc -> find_functions(node, acc) end)
  end

  def find_functions({_, _, list}, acc) when is_list(list) do
    Enum.reduce(list, acc, fn node, acc -> find_functions(node, acc) end)
  end

  def find_functions(_, acc), do: acc

  def add_documentation(
        command,
        [%{module: module, func_name: func_name, func_ary: func_ary} | rest],
        docs
      ) do
    regex = ~r/#{module}.#{Regex.escape(Atom.to_string(func_name))}/
    [before, _, remaining_command] = Regex.split(regex, command, include_captures: true, parts: 2)

    case docs[%{func_name: "#{module}.#{func_name}", func_ary: func_ary}] do
      nil ->
        [before, "#{module}.#{func_name}"] ++ add_documentation(remaining_command, rest, docs)

      doc ->
        [before, {"#{module}.#{func_name}", doc}] ++
          add_documentation(remaining_command, rest, docs)
    end
  end

  def add_documentation(command, [], _) do
    [command]
  end

  def retrive_docs([module | remaining_modules]) do
    {:docs_v1, _, :elixir, _, _, _, list} = Code.fetch_docs(module)

    docs =
      Enum.reduce(list, %{}, fn function, acc ->
        case function do
          {{:function, func_name, func_ary}, _, _header, %{"en" => docs}, _} ->
            {:ok, html_doc, _} = Earmark.as_html(docs)
            [module_name] = Module.split(module)

            Map.put(acc, %{func_name: "#{module_name}.#{func_name}", func_ary: func_ary}, %{
              header: "#{module_name}.#{func_name}/#{func_ary}",
              docs: html_doc
            })

          _ ->
            acc
        end
      end)

    Map.merge(docs, retrive_docs(remaining_modules))
  end

  def retrive_docs([]), do: %{}
end

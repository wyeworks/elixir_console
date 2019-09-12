defmodule ContextualHelp do
  def compute(command) do
    docs = docs(Enum)

    Regex.split(regex(docs), command, include_captures: true)
    |> Enum.map(fn part ->
      if part in Map.keys(docs) do
        {part, docs[part]}
      else
        part
      end
    end)
  end

  def regex(docs) do
    {:ok, regex} = docs
      |> Map.keys
      |> Enum.join("|")
      |> Regex.compile

    regex
  end

  def docs(module) do
    {:docs_v1, _, :elixir, _, _, _, list} = Code.fetch_docs(module)

    Enum.reduce(list, %{}, fn function, acc ->
      case function do
        {{:function, func_name, _func_ary}, _, _header, %{"en" => doc}, _} ->
          {:ok, html_doc, _} = Earmark.as_html(doc)
          Map.put(acc, "Enum.#{func_name}", html_doc)
        _ ->
          acc
      end
    end)
  end
end

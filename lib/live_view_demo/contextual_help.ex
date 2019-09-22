defmodule ContextualHelp do
  @func_name_regex ~r{^(?<func_name>[[:alnum:]]+\.[[:alnum:]_?]+)}

  def compute(command) do
    # TODO Enum is harcoded
    docs = docs(Enum)

    Regex.split(regex(docs), command, include_captures: true)
    |> Enum.reduce([], fn part, acc ->
      with [[func_name]] <- Regex.scan(@func_name_regex, part, capture: ["func_name"]),
        {:ok, {_, _, params} } <- Code.string_to_quoted(part),
        arity <- Enum.count(params),
        ["", func_name_part, remaining] <- Regex.split(@func_name_regex, part, include_captures: true),
        doc when not is_nil(doc) <- docs[%{func_name: func_name, func_ary: arity}] do

          acc ++ [
            {func_name_part, doc},
            remaining
          ]
        else
          _ ->
            acc ++ [part]
      end
    end)
  end

  def regex(docs) do
    {:ok, regex} = docs
      |> Map.keys
      |> Enum.map(fn func_meta ->
        # TODO consider 0 params
        # TODO ^^ we should consider using quoted_from_string in order to cover all cases
        args_matcher = for _ <- 1..func_meta[:func_ary]-1, do: ".*"
        args = Enum.join(args_matcher, ", ")

        "#{func_meta[:func_name]}\\(#{args}\\)|#{func_meta[:func_name]} #{args}"
      end)
      |> Enum.join("|")
      |> Regex.compile

    regex
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

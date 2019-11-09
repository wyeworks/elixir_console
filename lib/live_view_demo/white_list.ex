defmodule LiveViewDemo.WhiteList do
  @moduledoc """
  Analize the ast to filter out non white-listed modules and kernel functions
  """

  @valid_modules [:List, :Enum]

  def validate(command) do
    {_, result} =
      Code.string_to_quoted!(command)
      |> Macro.prewalk([], &valid?(&1, &2))

    result
    |> Enum.filter(&match?({:error, _}, &1))
    |> Enum.map(fn {:error, module} -> module end)
    |> case do
      [] ->
        {:ok, command}

      invalid_modules ->
        {:error, "Invalid modules: #{inspect(invalid_modules)}"}
    end
  end

  defp valid?({:__aliases__, _, [module]} = elem, acc) when module not in @valid_modules do
    {elem, [{:error, module} | acc]}
  end

  defp valid?(elem, acc), do: {elem, [:ok | acc]}
end

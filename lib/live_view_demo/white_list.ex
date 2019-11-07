defmodule LiveViewDemo.WhiteList do
  @moduledoc """
  Analize the ast to filter out non white-listed modules and kernel functions
  """

  @valid_modules [:List, :Enum]

  def validate(command) do
    {_, result} =
      Code.string_to_quoted!(command)
      |> Macro.prewalk([], &valid?(&1, &2))

    if Enum.member?(result, :error) do
      {:error, "Module not available"}
    else
      {:ok, command}
    end
  end

  defp valid?({:__aliases__, _, [module]} = elem, acc) when module not in @valid_modules do
    {elem, [:error | acc]}
  end

  defp valid?(elem, acc), do: {elem, [:ok | acc]}
end

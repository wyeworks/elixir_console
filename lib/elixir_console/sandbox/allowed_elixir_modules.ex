defmodule ElixirConsole.Sandbox.AllowedElixirModules do
  @moduledoc """
  Analyze the AST to filter out non white-listed modules and kernel functions
  """

  alias ElixirConsole.Sandbox.CommandValidator
  @behaviour CommandValidator

  @valid_modules ElixirConsole.ElixirSafeParts.safe_modules()

  @impl CommandValidator
  def validate(ast) do
    {_ast, result} = Macro.prewalk(ast, [], &valid?(&1, &2))

    result
    |> Enum.filter(&match?({:error, _}, &1))
    |> Enum.map(fn {:error, module} -> module end)
    |> Enum.dedup()
    |> case do
      [] ->
        :ok

      invalid_modules ->
        {:error,
         "Some Elixir modules are not allowed to be used. " <>
           "Not allowed modules attempted: #{inspect(invalid_modules)}"}
    end
  end

  defp valid?({:__aliases__, _, [module]} = elem, acc) when module not in @valid_modules do
    {elem, [{:error, module} | acc]}
  end

  defp valid?(elem, acc), do: {elem, [:ok | acc]}
end

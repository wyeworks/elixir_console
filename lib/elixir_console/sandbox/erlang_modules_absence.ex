defmodule ElixirConsole.Sandbox.ErlangModulesAbsence do
  @moduledoc """
  Analyze the AST and check if Erlang modules are not present.
  """

  alias ElixirConsole.Sandbox.{CommandValidator, Util}
  @behaviour CommandValidator

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
         "It is not allowed to invoke non-Elixir modules. " <>
           "Not allowed modules attempted: #{inspect(invalid_modules)}"}
    end
  end

  defp valid?({:., _, [module, _]} = elem, acc) do
    if Util.is_erlang_module?(module) do
      {elem, [{:error, module} | acc]}
    else
      {elem, acc}
    end
  end

  defp valid?(elem, acc), do: {elem, acc}
end

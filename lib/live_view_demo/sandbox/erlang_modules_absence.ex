defmodule LiveViewDemo.Sandbox.ErlangModulesAbsence do
  @moduledoc """
  Analyze the AST and check if Erlang modules are not present.
  """

  alias LiveViewDemo.Sandbox.CommandValidator
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
        {:error, "It is not allowed to invoke non-Elixir modules: #{inspect(invalid_modules)}"}
    end
  end

  defp valid?({:., _, [erlang_module, _]} = elem, acc) when is_atom(erlang_module) do
    {elem, [{:error, erlang_module} | acc]}
  end

  defp valid?(elem, acc), do: {elem, acc}
end

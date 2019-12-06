defmodule ElixirConsole.Sandbox.ErlangModulesAbsence do
  @moduledoc """
  Analyze the AST and check if Erlang modules are not present.
  """

  alias ElixirConsole.Sandbox.CommandValidator
  @behaviour CommandValidator

  @az_range 97..122

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
    if is_erlang_module?(module) do
      {elem, [{:error, module} | acc]}
    else
      {elem, acc}
    end
  end

  defp valid?(elem, acc), do: {elem, acc}

  defp is_erlang_module?(module) when not is_atom(module), do: false

  defp is_erlang_module?(module) do
    module
    |> to_charlist
    |> starts_with_lowercase?
  end

  defp starts_with_lowercase?([first_char | _]) when first_char in @az_range, do: true
  defp starts_with_lowercase?(_module_charlist), do: false
end

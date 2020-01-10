defmodule ElixirConsole.Sandbox.ExcludeConversionToAtoms do
  @moduledoc """
  Check if the command from untrusted source is free of calls that
  programmatically create atoms.
  """

  alias ElixirConsole.Sandbox.CommandValidator
  @behaviour CommandValidator

  @impl CommandValidator
  def validate(ast) do
    {_ast, result} = Macro.prewalk(ast, :ok, &valid?(&1, &2))

    if result == :error do
      {:error,
       "It is not allowed to programmatically convert to atoms. " <>
         "Consider using String.to_existing_atom/1"}
    else
      :ok
    end
  end

  defp valid?(elem, :error), do: {elem, :error}

  defp valid?({:., _, [{:__aliases__, _, [module]}, function]} = elem, _acc)
       when function == :to_atom and module in [:String, :List] do
    {elem, :error}
  end

  defp valid?(elem, acc), do: {elem, acc}
end

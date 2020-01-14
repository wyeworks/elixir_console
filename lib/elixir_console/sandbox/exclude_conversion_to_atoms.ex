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

    case result do
      :to_atom_error ->
        {:error,
         "Programmatically creation of atoms is not allowed in this online console. " <>
           "Consider using String.to_existing_atom/1"}

      :atom_modifier_in_sigils ->
        {:error,
         "Programmatically creation of atoms is not allowed in this online console. " <>
           "For this reason, the `a` modifier is not allowed when using ~w. " <>
           "Instead, try using ~W since it does not interpolate the content"}

      :ok ->
        :ok
    end
  end

  defp valid?(elem, result) when result != :ok, do: {elem, result}

  defp valid?({:., _, [{:__aliases__, _, [module]}, function]} = elem, _acc)
       when function == :to_atom and module in [:String, :List] do
    {elem, :to_atom_error}
  end

  defp valid?({:sigil_w, _, [_, 'a']} = elem, _acc) do
    {elem, :atom_modifier_in_sigils}
  end

  defp valid?(elem, acc), do: {elem, acc}
end

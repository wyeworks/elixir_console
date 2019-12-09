defmodule ElixirConsole.Sandbox.SafeKernelFunctions do
  @moduledoc """
  Check if a command from untrusted source is using only safe Kernel functions
  """

  alias ElixirConsole.Sandbox.CommandValidator
  @behaviour CommandValidator

  @kernel_functions_blacklist ElixirConsole.ElixirSafeParts.unsafe_kernel_functions()

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

      unsafe_functions ->
        {:error,
         "It is allowed to invoke only safe Kernel functions. " <>
           "Not allowed functions attempted: #{inspect(unsafe_functions)}"}
    end
  end

  defp valid?({function, _, _} = elem, acc) when function in @kernel_functions_blacklist do
    {elem, [{:error, function} | acc]}
  end

  defp valid?({:., _, [{:__aliases__, _, [:Kernel]}, function]} = elem, acc)
       when function in @kernel_functions_blacklist do
    {elem, [{:error, function} | acc]}
  end

  defp valid?(elem, acc), do: {elem, acc}
end

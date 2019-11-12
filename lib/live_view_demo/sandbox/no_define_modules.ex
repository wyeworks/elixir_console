defmodule LiveViewDemo.Sandbox.NoDefineModules do
  @moduledoc """
  Check if a command from untrusted source does not define new modules
  """

  def validate(command) do
    {_ast, result} =
      command
      |> Code.string_to_quoted!()
      |> Macro.prewalk([], &valid?(&1, &2))

    if result do
      :ok
    else
      {:error, "Defining new modules is not allowed. Do not use `defmodule`."}
    end
  end

  defp valid?({:defmodule, _, _} = elem, _acc), do: {elem, false}
  defp valid?(elem, acc), do: {elem, acc}
end

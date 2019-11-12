defmodule LiveViewDemo.Sandbox.NoDefineModules do
  @moduledoc """
  Check if a command from untrusted source does not define new modules
  """

  alias LiveViewDemo.Sandbox.CommandValidator
  @behaviour CommandValidator

  @impl CommandValidator
  def validate(ast) do
    {_ast, result} = Macro.prewalk(ast, [], &valid?(&1, &2))

    if result do
      :ok
    else
      {:error, "Defining new modules is not allowed. Do not use `defmodule`."}
    end
  end

  defp valid?({:defmodule, _, _} = elem, _acc), do: {elem, false}
  defp valid?(elem, acc), do: {elem, acc}
end

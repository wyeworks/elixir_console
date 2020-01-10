defmodule ElixirConsole.Sandbox.Util do
  @moduledoc false

  @az_range 97..122

  def is_erlang_module?(module) when not is_atom(module), do: false

  def is_erlang_module?(module) do
    module
    |> to_charlist
    |> starts_with_lowercase?
  end

  defp starts_with_lowercase?([first_char | _]) when first_char in @az_range, do: true
  defp starts_with_lowercase?(_module_charlist), do: false
end

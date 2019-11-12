defmodule LiveViewDemo.Sandbox.CommandValidator do
  @moduledoc """
  Check if a given Elixir code from untrusted sources is safe to be executed in
  the sandbox. This module also defines a behavior to be implemented by
  validator modules, providing a mechanism to compose individual safety checks
  over the command.
  """

  @type ast :: Macro.t()
  @callback validate(ast()) :: :ok | {:error, String.t()}

  alias LiveViewDemo.Sandbox.{AllowedElixirModules, DefmodulesAbsence, ErlangModulesAbsence}

  @ast_validator_modules [DefmodulesAbsence, AllowedElixirModules, ErlangModulesAbsence]

  def safe_command?(command) do
    ast = Code.string_to_quoted!(command)

    Enum.reduce_while(@ast_validator_modules, nil, fn module, _acc ->
      case apply(module, :validate, [ast]) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end
end

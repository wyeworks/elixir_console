defmodule LiveViewDemo.Sandbox.CommandValidator do
  @type ast :: Macro.t()
  @callback validate(ast()) :: :ok | {:error, String.t()}

  alias LiveViewDemo.Sandbox.{NoDefineModules, AllowedElixirModules}

  @ast_validator_modules [NoDefineModules, AllowedElixirModules]

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

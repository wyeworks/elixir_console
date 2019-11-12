defmodule LiveViewDemo.Sandbox.CommandValidator do
  alias LiveViewDemo.Sandbox.{NoDefineModules, AllowedElixirModules}

  def safe_command?(command) do
    ast = Code.string_to_quoted!(command)

    with :ok <- NoDefineModules.validate(ast),
         :ok <- AllowedElixirModules.validate(ast) do
      :ok
    else
      error -> error
    end
  end
end

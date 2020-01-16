defmodule ElixirConsole.Sandbox.CodeExecutor do
  @moduledoc """
  This module is responsible to orchestrate the validation and execution of the
  user-provided code. It should be run inside the sandbox process.
  """

  require Logger

  alias ElixirConsole.Sandbox.{CommandValidator, RuntimeValidations}

  def execute_code(command, bindings) do
    Logger.info("Command to be executed: #{command}")

    try do
      with :ok <- CommandValidator.safe_command?(command),
           command_ast <- RuntimeValidations.get_augmented_ast(command),
           {result, bindings} <-
             Code.eval_quoted(command_ast, bindings, eval_context()) do
        {:success, {result, bindings}}
      else
        error -> error
      end
    rescue
      exception ->
        {:error, inspect(exception)}
    end
  end

  # This is just to make available Bitwise macros when evaluating user code
  # Bitwise is special because the module must be `used` to have access to their
  # macros
  defp eval_context do
    [
      requires: [Bitwise, Kernel],
      macros: [
        {Kernel, __ENV__.macros[Kernel]},
        {Bitwise,
         [
           &&&: 2,
           <<<: 2,
           >>>: 2,
           ^^^: 2,
           band: 2,
           bnot: 1,
           bor: 2,
           bsl: 2,
           bsr: 2,
           bxor: 2,
           |||: 2,
           ~~~: 1
         ]}
      ]
    ]
  end
end

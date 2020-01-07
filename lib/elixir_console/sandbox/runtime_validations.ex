defmodule ElixirConsole.Sandbox.RuntimeValidations do
  @moduledoc """
    This module injects code to the AST for code from untrusted sources. It
    ensures that non-secure functions are not invoked at runtime.
  """

  @this_module __MODULE__ |> Module.split() |> Enum.map(&String.to_atom/1)
  @valid_modules ElixirConsole.ElixirSafeParts.safe_elixir_modules()
  @kernel_functions_blacklist ElixirConsole.ElixirSafeParts.unsafe_kernel_functions()

  @doc """
    Returns the AST for the given Elixir code but including invocations to
    `safe_invocation/2` before invoking any given function (based on the
    presence of the :. operator)
  """
  def get_augmented_ast(command) do
    ast = Code.string_to_quoted!(command)
    {augmented_ast, _result} = Macro.postwalk(ast, nil, &add_safe_invocation(&1, &2))

    augmented_ast
  end

  defp add_safe_invocation({:., meta, [callee, function]}, acc) do
    elem =
      {:., meta,
       [
         {
           {:., meta,
            [
              {:__aliases__, meta, @this_module},
              :safe_invocation
            ]},
           meta,
           [callee, function]
         },
         function
       ]}

    {elem, acc}
  end

  defp add_safe_invocation(elem, acc), do: {elem, acc}

  @doc """
    This function is meant to be invoked before calling a function (from an
    expression with the form `foo.bar`), so the Sandbox can effectively check if
    this invocation is considered safe. In case of success, the callee is
    returned. In this way, this function can be inlined in the original
    expression (like `safe_invocation(foo, bar).bar`).
  """
  def safe_invocation(callee, _) when callee not in @valid_modules do
    raise "Sandbox runtime error: It is not allowed to use some Elixir modules. " <>
            "Not allowed module attempted: #{inspect(callee)}"
  end

  def safe_invocation(Kernel, function) when function in @kernel_functions_blacklist do
    raise "Sandbox runtime error: It is not allowed to use some Elixir modules. " <>
            "Not allowed function attempted: #{inspect(function)}"
  end

  def safe_invocation(String, :to_atom) do
    raise "Sandbox runtime error: String.to_atom/1 is not allowed."
  end

  def safe_invocation(callee, _function) do
    if ElixirConsole.Sandbox.Util.is_erlang_module?(callee) do
      raise "It is not allowed to invoke non-Elixir modules. " <>
              "Not allowed module attempted: #{inspect(callee)}"
    else
      callee
    end
  end
end

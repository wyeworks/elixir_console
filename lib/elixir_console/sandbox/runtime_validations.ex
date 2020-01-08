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
    {augmented_ast, _result} = Macro.prewalk(ast, nil, &add_safe_invocation(&1, &2))

    augmented_ast
  end

  defp add_safe_invocation(
         {:|>, outer_meta,
          [first_param, {{:., meta, [callee, function]}, meta, remaining_params}]},
         acc
       ) do
    params = [first_param | remaining_params]

    elem =
      {{:., outer_meta,
        [
          {:__aliases__, meta, @this_module},
          :safe_invocation
        ]}, meta, [callee, function, params]}

    {elem, acc}
  end

  defp add_safe_invocation({{:., meta, [callee, function]}, outer_meta, params}, acc) do
    elem =
      {{:., outer_meta,
        [
          {:__aliases__, meta, @this_module},
          :safe_invocation
        ]}, meta, [callee, function, params]}

    {elem, acc}
  end

  defp add_safe_invocation(elem, acc), do: {elem, acc}

  @doc """
    This function is meant to be injected into the modified AST so we have safe
    invocations. The original invocation is done once it is validated as a
    secure call.
  """
  def safe_invocation(callee, _, _) when callee not in @valid_modules do
    raise "Sandbox runtime error: It is not allowed to use some Elixir modules. " <>
            "Not allowed module attempted: #{inspect(callee)}"
  end

  def safe_invocation(Kernel, function, _) when function in @kernel_functions_blacklist do
    raise "Sandbox runtime error: It is not allowed to use some Elixir modules. " <>
            "Not allowed function attempted: #{inspect(function)}"
  end

  def safe_invocation(String, :to_atom, _) do
    raise "Sandbox runtime error: String.to_atom/1 is not allowed."
  end

  # TODO generalize to other macros from Kernel and Integer (and for other modules?)
  def safe_invocation(Kernel, :to_string, params) do
    apply(&to_string(&1), params)
  end

  def safe_invocation(Integer, :is_odd, params) do
    require Integer
    apply(&Integer.is_odd(&1), params)
  end

  def safe_invocation(Integer, :is_even, params) do
    require Integer
    apply(&Integer.is_even(&1), params)
  end

  def safe_invocation(callee, function, params) do
    if ElixirConsole.Sandbox.Util.is_erlang_module?(callee) do
      raise "It is not allowed to invoke non-Elixir modules. " <>
              "Not allowed module attempted: #{inspect(callee)}"
    else
      apply(callee, function, params)
    end
  end
end

defmodule ElixirConsole.Sandbox.RuntimeValidations do
  @moduledoc """
    This module injects code to the AST for code from untrusted sources. It
    ensures that non-secure functions are not invoked at runtime.
  """

  alias ElixirConsole.{ElixirSafeParts, Sandbox.Util}

  @this_module __MODULE__ |> Module.split() |> Enum.map(&String.to_atom/1)
  @valid_modules ElixirSafeParts.safe_elixir_modules()
  @kernel_functions_blacklist ElixirSafeParts.unsafe_kernel_functions()

  @max_string_duplication_times 100_000

  # Random string that is large enough so it does not collide with user's code
  @keep_dot_operator_mark Util.random_atom(64)

  @doc """
    Returns the AST for the given Elixir code but including invocations to
    `safe_invocation/2` before invoking any given function (based on the
    presence of the :. operator)
  """
  def get_augmented_ast(command) do
    ast = Code.string_to_quoted!(command)

    {augmented_ast, _result} =
      Macro.traverse(ast, nil, &add_safe_invocation(&1, &2), &restore_dot_operator(&1, &2))

    augmented_ast
  end

  # Do not inline a `safe_invocation` call when the dot operator is used to access
  # nested structures
  defp add_safe_invocation({{:., _, [{{:., _, [Access, :get]}, _, _}, _]}, _, _} = elem, acc),
    do: {elem, acc}

  defp add_safe_invocation({{:., _, [Access, :get]}, _, _} = elem, acc), do: {elem, acc}

  # Do not inline a `safe_invocation` call when the dot operator is used in
  # function capturing. Note it is using the special token.
  # @keep_dot_operator_mark to prevent the modification of the inner node with
  # the dot operator. restore_dot_operator/2 is responsible for restoring the
  # AST by replacing token occurrences with the :. atom
  defp add_safe_invocation(
         {:&, outer_meta,
          [
            {:/, middle_meta,
             [
               {{:., inner_meta, [{:__aliases__, meta, [module]}, function]}, inner_params,
                outer_params},
               arity
             ]}
          ]},
         acc
       )
       when is_atom(module) and is_atom(function) and is_integer(arity) do
    elem =
      {:&, outer_meta,
       [
         {:/, middle_meta,
          [
            {{@keep_dot_operator_mark, inner_meta, [{:__aliases__, meta, [module]}, function]},
             inner_params, outer_params},
            arity
          ]}
       ]}

    {elem, acc}
  end

  # Inline `safe_invocation` call when dot operator implies to invoke a function
  # (this is exactly the case we want to intercept)
  defp add_safe_invocation({{:., meta, [callee, function]}, outer_meta, params}, acc)
       when is_atom(callee) or is_tuple(callee) do
    elem =
      {{:., outer_meta,
        [
          {:__aliases__, meta, @this_module},
          :safe_invocation
        ]}, meta, [callee, function, params]}

    {elem, acc}
  end

  # Also inline a `safe_invocation` call when pipe operator is used, since it is
  # equivalent to direct invocation
  defp add_safe_invocation(
         {:|>, outer_meta,
          [first_param, {{:., meta, [callee, function]}, _more_meta, remaining_params}]},
         acc
       )
       when is_atom(callee) or is_tuple(callee) do
    params = [first_param | remaining_params]

    elem =
      {{:., outer_meta,
        [
          {:__aliases__, meta, @this_module},
          :safe_invocation
        ]}, meta, [callee, function, params]}

    {elem, acc}
  end

  defp add_safe_invocation(elem, acc), do: {elem, acc}

  # Note that add_safe_invocation/2 could interchange a dot operator by an
  # special token (@keep_dot_operator_mark) in cases where the dot operator does
  # not represents an invocation (situation that is determined by the parent
  # nodes). This function restores the original :. occurrences.
  defp restore_dot_operator(
         {{@keep_dot_operator_mark, meta, [callee, function]}, outer_meta, params},
         acc
       ) do
    elem = {{:., meta, [callee, function]}, outer_meta, params}

    {elem, acc}
  end

  defp restore_dot_operator(elem, acc), do: {elem, acc}

  @doc """
    This function is meant to be injected into the modified AST so we have safe
    invocations. The original invocation is done once it is validated as a
    secure call.
  """
  def safe_invocation(callee, _, _) when is_atom(callee) and callee not in @valid_modules do
    raise "Sandbox runtime error: Some Elixir modules are not allowed to be used. " <>
            "Not allowed module attempted: #{inspect(callee)}"
  end

  def safe_invocation(Kernel, function, _) when function in @kernel_functions_blacklist do
    raise "Sandbox runtime error: Some Kernel functions/macros are not allowed to be used. " <>
            "Not allowed function/macro attempted: #{inspect(function)}"
  end

  def safe_invocation(String, :to_atom, _) do
    raise "Sandbox runtime error: String.to_atom/1 is not allowed."
  end

  def safe_invocation(String, :duplicate, [_, times])
      when times >= @max_string_duplication_times do
    raise "Sandbox runtime error: String.duplicate/2 is not safe to be executed " <>
            "when the second parameter is a very large number."
  end

  def safe_invocation(String, function, [_, times, _])
      when times >= @max_string_duplication_times and function in [:pad_leading, :pad_trailing] do
    raise "Sandbox runtime error: String.#{function}/3 is not safe to be executed " <>
            "when the second parameter is a very large number."
  end

  # This approach is not working well with Kernel macros that are invoked with
  # explicit callee (e.g. Kernel.to_string/1). The following functions cover a
  # little portion of the existing cases. Future work can be done to transform
  # AST converting those macro calls to implicit invocations.

  # In particular, Kernel.to_string/1 must be supported because of string
  # interpolation. This is the only one that is very important to have done.
  def safe_invocation(Kernel, :to_string, [param]) do
    to_string(param)
  end

  # A few extra cases that are cheap to cover
  def safe_invocation(Kernel, :binding, params) do
    apply(&binding(&1), params)
  end

  def safe_invocation(Kernel, :is_nil, [param]) do
    is_nil(param)
  end

  def safe_invocation(Kernel, :to_charlist, [param]) do
    to_charlist(param)
  end

  # Integer macros
  require Integer

  def safe_invocation(Integer, :is_odd, param) do
    Integer.is_odd(param)
  end

  def safe_invocation(Integer, :is_even, param) do
    Integer.is_even(param)
  end

  # Case where dot operator is used as a way to access a nested structure We are
  # still adding the safe_invocation call, just to make sure the callee is not
  # an atom but we can not resolve it using Kernel.apply/3
  def safe_invocation(term, key, []) when is_map(term) and is_atom(key) do
    case Access.fetch(term, key) do
      {:ok, result} -> result
      :error -> %KeyError{key: key, message: nil, term: term}
    end
  end

  # Base case
  def safe_invocation(callee, function, params) when is_atom(callee) do
    apply(callee, function, params)
  end

  def safe_invocation(callee, function, params) do
    try do
      Sentry.capture_message("safe_invocation unexpected case",
        extra: %{callee: callee, function: function, params: params}
      )
    after
      raise "Internal error. Please fill an issue at https://github.com/wyeworks/elixir_console/issues."
    end
  end
end

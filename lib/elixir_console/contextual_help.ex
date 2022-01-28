defmodule ElixirConsole.ContextualHelp do
  @moduledoc """
  Utilities to add metadata to an user-generated Elixir command about the
  standard library functions that are in use.
  """

  alias ElixirConsole.Documentation

  @kernel_binary_operators ~w(
    !=
    !==
    *
    -
    +
    /
    <
    <=
    ==
    ===
    >
    >=
    &&
    ++
    --
    ..
    **
    <>
    =~
    |>
    ||
    and
    or
    in
  )a

  @kernel_functions ~w(
    abs
    binary_part
    bit_size
    byte_size
    ceil
    div
    elem
    floor
    hd
    is_atom
    is_binary
    is_bitstring
    is_boolean
    is_exception
    is_float
    is_function
    is_integer
    is_list
    is_map
    is_map_key
    is_nil
    is_number
    is_reference
    is_struct
    is_tuple
    length
    map_size
    not
    rem
    round
    self
    tl
    trunc
    tuple_size
    !
    binding
    function_exported?
    get_and_update_in
    get_in
    if
    inspect
    macro_exported?
    make_ref
    match?
    max
    min
    pop_in
    put_elem
    put_in
    raise
    reraise
    struct
    struct!
    throw
    to_charlist
    to_string
    unless
    update_in
    tap
    then
  )a

  @doc """
  Takes an Elixir command and returns it divided in parts, and the ones that
  correspond to Elixir functions are augmented with metadata containing the docs
  """
  def compute(command) do
    case Code.string_to_quoted(command) do
      {:ok, expr} ->
        functions = find_functions(expr, [])
        add_documentation(command, functions)

      _ ->
        [command]
    end
  end

  defp find_functions(list, acc) when is_list(list) do
    Enum.reduce(list, acc, fn node, acc -> find_functions(node, acc) end)
  end

  defp find_functions({{:., _, [{_, _, [module]}, func_name]}, _, params}, acc)
       when is_atom(module) do
    acc = acc ++ [%{module: module, func_name: func_name, func_ary: Enum.count(params)}]
    Enum.reduce(params, acc, fn node, acc -> find_functions(node, acc) end)
  end

  defp find_functions({{:., _, nested_expression}, _, params}, acc) do
    acc = find_functions(nested_expression, acc)
    Enum.reduce(params, acc, fn node, acc -> find_functions(node, acc) end)
  end

  defp find_functions({func_name, _, params}, acc)
       when func_name in @kernel_functions and is_list(params) do
    acc = acc ++ [%{module: "Kernel", func_name: func_name, func_ary: Enum.count(params)}]
    Enum.reduce(params, acc, fn node, acc -> find_functions(node, acc) end)
  end

  defp find_functions({func_name, _, [left_param, right_param]}, acc)
       when func_name in @kernel_binary_operators do
    acc = find_functions(left_param, acc)
    acc = acc ++ [%{module: "Kernel", func_name: func_name, func_ary: 2}]
    find_functions(right_param, acc)
  end

  defp find_functions({_, _, list}, acc) when is_list(list) do
    Enum.reduce(list, acc, fn node, acc -> find_functions(node, acc) end)
  end

  defp find_functions({node_left, node_right}, acc) do
    find_functions(node_right, find_functions(node_left, acc))
  end

  defp find_functions(_, acc), do: acc

  defp add_documentation(command, []), do: [command]

  defp add_documentation(
         command,
         [%{module: module, func_name: func_name, func_ary: func_ary} | rest]
       ) do
    func_fullname = "#{module}.#{func_name}"
    regex = ~r/#{Regex.escape(func_fullname)}|#{Regex.escape(Atom.to_string(func_name))}/

    [before_matched, matched, remaining_command] =
      Regex.split(regex, command, include_captures: true, parts: 2)

    parts_to_add =
      case Documentation.get_doc(%Documentation.Key{func_name: func_fullname, arity: func_ary}) do
        nil ->
          [before_matched, matched]

        doc ->
          [before_matched, {matched, doc}]
      end

    parts_to_add ++ add_documentation(remaining_command, rest)
  end
end

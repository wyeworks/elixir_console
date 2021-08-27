defmodule ElixirConsole.ElixirSafeParts do
  @moduledoc """
  List of modules and functions considered safe to be executed by the Elixir
  Console

  The goal of the console is to run Elixir code from untrusted sources.
  Therefore, here is defined a few whitelists of Elixir modules and functions,
  in order to limit the accessible feature of the language that are at disposal
  """

  @safe_modules ~w(
    Kernel
    Atom
    Base
    Bitwise
    Date
    DateTime
    Float
    Integer
    NaiveDateTime
    Regex
    String
    Time
    Tuple
    URI
    Version
    Version.Requirement
    Access
    Date.Range
    Enum
    Keyword
    List
    Map
    MapSet
    Range
    Stream
    OptionParser
    Collectable
    Enumerable
  )a

  @safe_kernel_functions ~w(
    !
    &&
    ++
    --
    ..
    <>
    =~
    binding
    get_and_update_in
    get_in
    if
    inspect
    make_ref
    match?
    max
    min
    pop_in
    put_elem
    put_in
    raise
    reraise
    sigil_C
    sigil_D
    sigil_N
    sigil_R
    sigil_S
    sigil_T
    sigil_U
    sigil_W
    sigil_c
    sigil_r
    sigil_s
    sigil_w
    struct
    struct!
    throw
    to_charlist
    to_string
    unless
    update_in
    |>
    ||
    !=
    !==
    *
    +
    -
    /
    <=
    <
    ==
    ===
    >
    >=
    abs
    and
    binary_part
    bit_size
    byte_size
    ceil
    div
    elem
    floor
    hd
    in
    is_atom
    is_binary
    is_bitstring
    is_boolean
    is_float
    is_function
    is_integer
    is_list
    is_map
    is_map_key
    is_nil
    is_number
    is_pid
    is_port
    is_reference
    is_struct
    is_tuple
    length
    map_size
    not
    or
    rem
    round
    self
    tl
    trunc
    tuple_size
    %
    %{}
    &
    .
    ::
    <<>>
    =
    ^
    __aliases__
    __block__
    case
    cond
    fn
    for
    try
    with
    {}
  )a

  def safe_modules, do: @safe_modules

  def safe_elixir_modules, do: Enum.map(@safe_modules, &:"Elixir.#{&1}")

  def unsafe_kernel_functions do
    all_kernel_functions() -- @safe_kernel_functions
  end

  defp all_kernel_functions do
    all_kernel_functions_raw() |> Keyword.keys() |> Enum.uniq()
  end

  defp all_kernel_functions_raw do
    Kernel.__info__(:functions) ++
      Kernel.__info__(:macros) ++ Kernel.SpecialForms.__info__(:macros)
  end
end

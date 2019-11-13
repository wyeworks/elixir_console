defmodule LiveViewDemo.Sandbox.SafeKernelFunctions do
  @moduledoc """
  Check if a command from untrusted source is using only safe Kernel functions
  """

  alias LiveViewDemo.Sandbox.CommandValidator
  @behaviour CommandValidator

  @kernel_functions_blacklist ~w(
    apply
    def
    defdelegate
    defexception
    defguard
    defguardp
    defimpl
    defmacro
    defmacrop
    defmodule
    defoverridable
    defp
    defprotocol
    defstruct
    destructure
    send
    spawn
    spawn
    spawn_link
    spawn_link
    spawn_monitor
    spawn_monitor
    use
    var!
    __CALLER__
    __DIR__
    __ENV__
    __MODULE__
    __STACKTRACE__
    __block__
    alias
    import
    receive
    require
    super
  )a

  @impl CommandValidator
  def validate(ast) do
    {_ast, result} = Macro.prewalk(ast, [], &valid?(&1, &2))

    result
    |> Enum.filter(&match?({:error, _}, &1))
    |> Enum.map(fn {:error, module} -> module end)
    |> Enum.dedup()
    |> case do
      [] ->
        :ok

      unsafe_functions ->
        {:error,
         "It is allowed to invoke only safe Kernel functions. " <>
           "Not allowed functions attempted: #{inspect(unsafe_functions)}"}
    end
  end

  defp valid?({:., _, [{:__aliases__, _, [:Kernel]}, function]} = elem, acc) when function in @kernel_functions_blacklist do
    {elem, [{:error, function} | acc]}
  end

  defp valid?({:., _, [Kernel, function]} = elem, acc) when function in @kernel_functions_blacklist do
    {elem, [{:error, function} | acc]}
  end

  defp valid?({function, _, _} = elem, acc) when function in @kernel_functions_blacklist do
    {elem, [{:error, function} | acc]}
  end

  defp valid?(elem, acc), do: {elem, acc}
end

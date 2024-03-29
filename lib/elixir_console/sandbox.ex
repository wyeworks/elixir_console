defmodule ElixirConsole.Sandbox do
  @moduledoc """
  Provides a sandbox where Elixir code from untrusted sources can be executed
  """

  @type sandbox() :: %__MODULE__{}

  alias ElixirConsole.Sandbox.CodeExecutor

  @max_command_length 500
  @max_memory_kb_default 256
  @max_binary_memory_kb_default 50 * 1024
  @timeout_ms_default 5000
  @check_every_ms_default 20
  @bytes_in_kb 1024

  @enforce_keys [:pid, :bindings]
  defstruct [:pid, :bindings]

  @doc """
  Initialize and returns a process where Elixir code will run in "sandbox mode".
  This is useful if we want to provide the chance to more than one individual
  command, where the user can assume it is always working the same process (as
  it happens when someone runs different commands in iex).

  Returns a Sandbox struct including the dedicated process and an empty list of
  bindings.
  """
  @spec init() :: sandbox()
  def init() do
    loop = fn loop_func ->
      receive do
        {:command, command, bindings, parent_pid} ->
          result = CodeExecutor.execute_code(command, bindings)
          send(parent_pid, {:result, result})

          loop_func.(loop_func)
      end
    end

    creator_pid = self()

    pid =
      spawn(fn ->
        # Add some metadata to those process to identify them, allowing to further
        # analysis
        Process.put(:sandbox_owner, creator_pid)
        loop.(loop)
      end)

    %__MODULE__{pid: pid, bindings: []}
  end

  @doc """
  Executes a command (Elixir code in a string) in the process given by the
  Sandbox struct provided.

  Returns the result of the execution and a Sandbox struct with the changes in
  the bindings, if the command succeeded. In case of errors, it returns an
  `{:error, error_message}` tuple where the second element is a string with an
  explanation.

  If the execution takes more time than the specified timeout, an error is
  returned. In addition, if the execution uses more memory than the allowed
  amount, it is interrupted and an error is returned.

  You can use the following options in the `opts` argument:

  `timeout`: Time limit to run the command (in milliseconds). The default is
  5000.

  `max_memory_kb`: Memory usage limit (expressed in Kb). The default is
  30.

  `check_every`: Determine the time elapsed between checks where memory
  usage is measured (expressed in Kb). The default is 20.
  """
  @typep execution_result() :: {binary(), sandbox()}
  @spec execute(binary(), sandbox(), keyword()) ::
          {:success, execution_result()} | {:error, execution_result()}
  def execute(command, sandbox, opts \\ [])

  def execute(command, sandbox, _) when byte_size(command) > @max_command_length do
    {:error, {"Command is too long. Try running a shorter piece of code.", sandbox}}
  end

  def execute(command, sandbox, opts) do
    task = Task.async(fn -> do_execute(command, sandbox, opts) end)
    Task.await(task, :infinity)
  end

  defp do_execute(command, sandbox, opts) do
    send(sandbox.pid, {:command, command, sandbox.bindings, self()})

    case check_execution_status(sandbox.pid, normalize_options(opts)) do
      {:ok, {:success, {result, bindings}}} ->
        {:success, {result, %{sandbox | bindings: Enum.sort(bindings)}}}

      {:ok, {:error, result}} ->
        {:error, {result, sandbox}}

      :timeout ->
        {:error, {"The command was cancelled due to timeout", restore(sandbox)}}

      :memory_abuse ->
        {:error, {"The command used more memory than allowed", restore(sandbox)}}
    end
  end

  @doc """
  The sandbox process is exited. This function should be used when the sandbox
  is not longer needed so resources are properly disposed.
  """
  def terminate(%__MODULE__{pid: pid}) do
    Process.exit(pid, :kill)
  end

  defp normalize_options(opts) do
    timeout = Keyword.get(opts, :timeout, @timeout_ms_default)
    check_every = Keyword.get(opts, :check_every, @check_every_ms_default)
    ticks = floor(timeout / check_every)

    max_memory_kb = Keyword.get(opts, :max_memory_kb, @max_memory_kb_default) * @bytes_in_kb

    max_binary_memory_kb =
      Keyword.get(opts, :max_binary_memory_kb, @max_binary_memory_kb_default) * @bytes_in_kb

    [
      ticks: ticks,
      check_every: check_every,
      max_memory_kb: max_memory_kb,
      max_binary_memory_kb: max_binary_memory_kb
    ]
  end

  defp restore(sandbox) do
    %__MODULE__{sandbox | pid: init().pid}
  end

  defp check_execution_status(pid, [{:ticks, 0} | _]) do
    Process.exit(pid, :kill)
    :timeout
  end

  defp check_execution_status(
         pid,
         [
           ticks: ticks,
           check_every: check_every,
           max_memory_kb: max_memory_kb,
           max_binary_memory_kb: max_binary_memory_kb
         ] = opts
       ) do
    receive do
      {:result, result} ->
        {:ok, result}
    after
      check_every ->
        if allowed_memory_usage_by_process?(pid, max_memory_kb) and
             allowed_memory_usage_in_binaries?(max_binary_memory_kb) do
          check_execution_status(pid, Keyword.put(opts, :ticks, ticks - 1))
        else
          Process.exit(pid, :kill)
          :memory_abuse
        end
    end
  end

  defp allowed_memory_usage_by_process?(pid, memory_limit) do
    {:memory, memory} = Process.info(pid, :memory)
    memory <= memory_limit
  end

  defp allowed_memory_usage_in_binaries?(binaries_memory_limit) do
    :erlang.memory(:binary) <= binaries_memory_limit
  end
end

defmodule LiveViewDemo.Sandbox do
  @moduledoc """
  Provides a sandbox where Elixir code from untrusted sources can be executed
  """

  @type sandbox() :: %__MODULE__{}

  require Logger
  alias LiveViewDemo.Sandbox.{CommandSanitizer, CommandValidator}

  @max_memory_kb_default 30
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
          result = execute_code(command, bindings)
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
          {:success, execution_result()} | {:error, binary()}
  def execute(command, sandbox, opts \\ []) do
    task = Task.async(fn -> do_execute(command, sandbox, opts) end)
    Task.await(task, :infinity)
  end

  defp do_execute(command, sandbox, opts) do
    send(sandbox.pid, {:command, command, sandbox.bindings, self()})

    timeout = Keyword.get(opts, :timeout, @timeout_ms_default)
    check_every = Keyword.get(opts, :check_every, @check_every_ms_default)
    ticks = floor(timeout / check_every)

    max_memory_kb = Keyword.get(opts, :max_memory_kb, @max_memory_kb_default) * @bytes_in_kb

    case check_execution_status(sandbox.pid,
           ticks: ticks,
           check_every: check_every,
           max_memory_kb: max_memory_kb
         ) do
      {:ok, {:success, {result, bindings}}} ->
        {:success, {result, %{sandbox | bindings: bindings}}}

      {:ok, {:error, result}} ->
        {:error, {result, sandbox}}

      :timeout ->
        {:error, {"The command was cancelled due to timeout", restore(sandbox)}}

      :memory_abuse ->
        {:error, {"The command used more memory than allowed", restore(sandbox)}}
    end
  end

  defp restore(sandbox) do
    %{sandbox | pid: init().pid}
  end

  defp check_execution_status(pid, [{:ticks, 0} | _]) do
    Process.exit(pid, :kill)
    :timeout
  end

  defp check_execution_status(
         pid,
         [ticks: ticks, check_every: check_every, max_memory_kb: max_memory_kb] = opts
       ) do
    receive do
      {:result, result} ->
        {:ok, result}
    after
      check_every ->
        if allowed_memory_usage?(pid, max_memory_kb) do
          check_execution_status(pid, Keyword.put(opts, :ticks, ticks - 1))
        else
          Process.exit(pid, :kill)
          :memory_abuse
        end
    end
  end

  defp allowed_memory_usage?(pid, memory_limit) do
    {:memory, memory} = Process.info(pid, :memory)
    memory <= memory_limit
  end

  def execute_code(command, bindings) do
    case CommandSanitizer.sanitize(command) do
      %{ast: ast, words_dict: words_dict} ->
        {bindings, words_dict} = CommandSanitizer.sanitize_bindings(bindings, words_dict)
        execute_ast(%{ast: ast, words_dict: words_dict}, bindings)
      {:error, error} ->
        {:error, error}
    end
  end

  defp execute_ast(%{ast: ast, words_dict: words_dict}, bindings) do
    try do
      with :ok <- CommandValidator.safe_command?(ast),
           {result, bindings} <- Code.eval_quoted(ast, bindings) do
        {:success, {result, CommandSanitizer.restore_bindings(bindings, words_dict)}}
      else
        {:error, error} ->
          {:error, CommandSanitizer.restore(error, words_dict)}
      end
    rescue
      exception ->
        {:error, CommandSanitizer.restore(inspect(exception), words_dict)}
    end
  end
end

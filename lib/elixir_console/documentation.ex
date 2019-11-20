defmodule ElixirConsole.Documentation do
  use GenServer

  defmodule Key do
    @enforce_keys [:func_name, :arity]
    defstruct [:func_name, :arity]
  end

  @modules [
    Access,
    Enum,
    Keyword,
    List,
    Map,
    MapSet,
    Range,
    Stream,
    File,
    IO,
    Path,
    Port,
    StringIO,
    System,
    Calendar,
    Agent,
    Application,
    Config,
    DynamicSupervisor,
    GenEvent,
    Node,
    Process,
    Registry,
    Task,
    Collectable,
    Enumerable,
    Inspect,
    Protocol,
    Code,
    Macro,
    Kernel
  ]

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, retrieve_docs(@modules)}
  end

  @impl true
  def handle_call({:get, key}, _from, docs) do
    {:reply, docs[key] || find_with_greater_arity(key, docs), docs}
  end

  @impl true
  def handle_call(:get_functions_names, _from, docs) do
    functions_names =
      Map.keys(docs)
      |> Enum.map(& &1.func_name)
      |> Enum.uniq()

    {:reply, functions_names, docs}
  end

  def get_doc(key), do: GenServer.call(__MODULE__, {:get, key})

  def get_functions_names(), do: GenServer.call(__MODULE__, :get_functions_names)

  defp retrieve_docs([module | remaining_modules]) do
    {:docs_v1, _, :elixir, _, _, _, list} = Code.fetch_docs(module)

    docs =
      Enum.reduce(list, %{}, fn function, acc ->
        case function do
          {{:function, func_name, func_ary}, _, header, %{"en" => docs}, _} ->
            {:ok, html_doc, _} = Earmark.as_html(docs)
            [module_name] = Module.split(module)

            Map.put(acc, %Key{func_name: "#{module_name}.#{func_name}", arity: func_ary}, %{
              func_name: "#{module_name}.#{func_name}/#{func_ary}",
              header: header,
              docs: html_doc,
              link: "https://hexdocs.pm/elixir/#{module_name}.html##{func_name}/#{func_ary}"
            })

          _ ->
            acc
        end
      end)

    Map.merge(docs, retrieve_docs(remaining_modules))
  end

  defp retrieve_docs([]), do: %{}

  defp find_with_greater_arity(%Key{func_name: func_name, arity: func_ary}, docs) do
    with {_, doc} <-
           Enum.filter(docs, fn {key, _} -> key.func_name == func_name && key.arity > func_ary end)
           |> Enum.sort(fn {k1, _}, {k2, _} -> k1.arity < k2.arity end)
           |> List.first() do
      doc
    else
      nil -> nil
    end
  end
end

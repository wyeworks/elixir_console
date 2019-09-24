defmodule LiveViewDemo.Documentation do
  use GenServer

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
    Macro
  ]

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, retrive_docs(@modules)}
  end

  @impl true
  def handle_call({:get, key}, _from, docs) do
    {:reply, docs[key], docs}
  end

  def get_doc(key), do: GenServer.call(__MODULE__, {:get, key})

  defp retrive_docs([module | remaining_modules]) do
    {:docs_v1, _, :elixir, _, _, _, list} = Code.fetch_docs(module)

    docs =
      Enum.reduce(list, %{}, fn function, acc ->
        case function do
          {{:function, func_name, func_ary}, _, _header, %{"en" => docs}, _} ->
            {:ok, html_doc, _} = Earmark.as_html(docs)
            [module_name] = Module.split(module)

            Map.put(acc, %{func_name: "#{module_name}.#{func_name}", func_ary: func_ary}, %{
              header: "#{module_name}.#{func_name}/#{func_ary}",
              docs: html_doc
            })

          _ ->
            acc
        end
      end)

    Map.merge(docs, retrive_docs(remaining_modules))
  end

  defp retrive_docs([]), do: %{}
end

defmodule ElixirConsole.Documentation do
  use GenServer

  defmodule Key do
    @enforce_keys [:func_name, :arity]
    defstruct @enforce_keys
  end

  defmodule DocEntry do
    @enforce_keys [:module_name, :func_name, :func_ary, :docs_header, :docs_body]
    defstruct @enforce_keys

    @az_range 97..122

    def build_docs_metadata(nil), do: nil

    def build_docs_metadata(doc_entry) do
      %DocEntry{
        module_name: module_name,
        func_name: func_name,
        func_ary: func_ary,
        docs_header: docs_header,
        docs_body: docs_body
      } = doc_entry

      %{
        type: function_or_operator(func_name),
        func_name: "#{module_name}.#{func_name}/#{func_ary}",
        header: docs_header,
        docs: docs_body,
        link: "https://hexdocs.pm/elixir/#{module_name}.html##{func_name}/#{func_ary}"
      }
    end

    defp function_or_operator(func_name) when is_atom(func_name) do
      func_name
      |> to_charlist
      |> function_or_operator
    end

    defp function_or_operator([first_char | _]) when first_char in @az_range, do: :function
    defp function_or_operator(_), do: :operator
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
    String,
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
    doc = docs[key] || find_with_greater_arity(key, docs)
    {:reply, DocEntry.build_docs_metadata(doc), docs}
  end

  @impl true
  def handle_call(:get_functions_names, _from, docs) do
    functions_names =
      Map.keys(docs)
      |> Enum.map(& &1.func_name)
      |> Enum.uniq()

    {:reply, functions_names, docs}
  end

  @impl true
  def handle_call(:get_kernel_functions_names, _from, docs) do
    functions_names =
      Map.values(docs)
      |> Enum.filter(&(&1.module_name == "Kernel"))
      |> Enum.map(&to_string(&1.func_name))
      |> Enum.uniq()

    {:reply, functions_names, docs}
  end

  @impl true
  def handle_call(:get_modules_names, _from, docs) do
    modules_names =
      Map.values(docs)
      |> Enum.map(& &1.module_name)
      |> Enum.uniq()

    {:reply, modules_names, docs}
  end

  def get_doc(key), do: GenServer.call(__MODULE__, {:get, key})

  def get_functions_names(), do: GenServer.call(__MODULE__, :get_functions_names)
  def get_kernel_functions_names(), do: GenServer.call(__MODULE__, :get_kernel_functions_names)
  def get_modules_names(), do: GenServer.call(__MODULE__, :get_modules_names)

  defp retrieve_docs([]), do: %{}

  defp retrieve_docs([module | remaining_modules]) do
    {:docs_v1, _, :elixir, _, _, _, list} = Code.fetch_docs(module)

    docs =
      Enum.reduce(list, %{}, fn function, acc ->
        case function do
          {{function_or_macro, func_name, func_ary}, _, header, %{"en" => docs}, _}
          when function_or_macro in [:function, :macro] ->
            {:ok, html_doc, _} = Earmark.as_html(docs)
            [module_name] = Module.split(module)

            Map.put(
              acc,
              %Key{func_name: "#{module_name}.#{func_name}", arity: func_ary},
              %DocEntry{
                module_name: module_name,
                func_name: func_name,
                func_ary: func_ary,
                docs_header: header,
                docs_body: html_doc
              }
            )

          _ ->
            acc
        end
      end)

    Map.merge(docs, retrieve_docs(remaining_modules))
  end

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

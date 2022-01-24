defmodule ElixirConsoleWeb.ConsoleLive.SidebarComponent do
  @moduledoc """
  Live component module that implements the portion of the UI corresponding to
  the sidebar. It displays the bindings, Elixir functions help and some static
  information.
  """

  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="w-full sm:w-32 md:w-1/3 h-32 sm:h-full bg-teal-800 text-gray-200 overflow-scroll flex flex-col">
      <.bindings bindings={@sandbox.bindings} />
      <div class="flex-1 flex flex-col justify-end p-2">
        <%= cond do %>
          <% @suggestions != [] -> %>
            <.suggestions suggestions={@suggestions}/>
          <% @contextual_help -> %>
            <.contextual_help {@contextual_help} />
          <% true -> %>
            <.instructions />
        <% end %>
      </div>
    </div>
    """
  end

  def bindings(assigns) do
    ~H"""
    <div class="bg-teal-700 p-2 overflow-y-scroll max-h-1/3">
      <h2 class="font-medium">Current Bindings</h2>
      <ul>
      <%= if length(@bindings) > 0 do %>
        <%= for {key, value} <- @bindings do %>
          <li class="truncate"><%= key %>: <code class="text-teal-300"><%= inspect(value) %></code></li>
        <% end %>
      <% else %>
        <code class="text-teal-300 text-sm">No bindings yet!</code>
      <% end %>
      </ul>
    </div>
    """
  end

  def suggestions(assigns) do
    ~H"""
    <h2 class="font-medium">Suggestions:</h2>
    <ul id="suggestions-list">
      <%= for suggestion <- @suggestions do %>
        <li><%= suggestion %></li>
      <% end %>
    </ul>
    """
  end

  def contextual_help(assigns) do
    ~H"""
    <div id="documentation-output">
      <span class="mb-8 font-bold text-green-400">
        <a href={@link} target="_blank" class="underline"><%= @func_name %></a>
      </span>
      <span class="text-xs mb-4 font-bold text-gray-200"><%= @header %></span>
      <span class="contextual-help-doc text-xs text-gray-200"><%= Phoenix.HTML.raw @doc %></span>
    </div>
    """
  end

  def instructions(assigns) do
    ~H"""
    <h2 class="underline mb-3">INSTRUCTIONS</h2>
    <p>[UP] [DOWN]: Navigate through commands history</p>
    <p>[TAB]: Get suggestions or autocomplete while typing</p>
    <p class="text-sm mt-3"> You can see the history panel that includes all your commands and their output.
    Click on any Elixir function to see here the corresponding documentation.</p>
    <h2 class="underline mt-5 mb-3">ABOUT SECURITY</h2>
    <p class="text-sm">Please note some features of the language are not safe to run in a shared environment like this console.
    If you are interested in knowing more about the limitations, you must <a class="underline" href="https://github.com/wyeworks/elixir_console#how-much-elixir-can-i-run-in-the-web-console">read here</a>.</p>
    <p class="text-sm">Please report any security vulnerabilities to
      <a class="underline" href="mailto:elixir-console-security@wyeworks.com">elixir-console-security@wyeworks.com</a>.
    </p>
    """
  end
end

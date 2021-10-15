defmodule ElixirConsoleWeb.ConsoleLive.ContextualHelp do
  use Surface.Component

  @doc "Link to documentation in hexdocs.pm"
  prop link, :string

  @doc "Name of the function"
  prop func_name, :string

  @doc "Header of the documentation"
  prop header, :string

  @doc "Body of the documentation"
  prop doc, :string

  def render(assigns) do
    ~F"""
    <div id="documentation-output">
      <span class="mb-8 font-bold text-green-400">
        <a href={@link} target="_blank" class="underline">{@func_name}</a>
      </span>
      <span class="text-xs mb-4 font-bold text-gray-200">{@header}</span>
      <span class="contextual-help-doc text-xs text-gray-200">{Phoenix.HTML.raw @doc}</span>
    </div>
    """
  end
end

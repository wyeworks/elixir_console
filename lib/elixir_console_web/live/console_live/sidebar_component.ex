defmodule ElixirConsoleWeb.ConsoleLive.SidebarComponent do
  @moduledoc """
  Live component module that implements the portion of the UI corresponding to
  the sidebar. It displays the bindings, Elixir functions help and some static
  information.
  """

  use Phoenix.LiveComponent

  def variable_name({name, _extra}), do: name
  def variable_name(other), do: other
end

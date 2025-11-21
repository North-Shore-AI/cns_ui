defmodule CnsUiWeb.Components.EvidenceTree do
  @moduledoc """
  Component for displaying evidence hierarchies as a tree structure.
  """

  use Phoenix.Component

  @doc """
  Renders an evidence tree component.

  ## Examples

      <.evidence_tree evidence={sno.evidence} />
  """
  attr :evidence, :map, required: true
  attr :expanded, :boolean, default: true
  attr :max_depth, :integer, default: 3

  def evidence_tree(assigns) do
    ~H"""
    <div class="font-mono text-sm">
      <%= if map_size(@evidence) > 0 do %>
        <.tree_node data={@evidence} depth={0} max_depth={@max_depth} />
      <% else %>
        <p class="text-gray-500 italic">No evidence data</p>
      <% end %>
    </div>
    """
  end

  defp tree_node(%{data: data, depth: _depth, max_depth: _max_depth} = assigns)
       when is_map(data) do
    ~H"""
    <div class={"#{if @depth > 0, do: "ml-4 border-l border-gray-200 pl-2"}"}>
      <%= for {key, value} <- @data do %>
        <div class="py-1">
          <span class="text-blue-600 font-medium"><%= key %>:</span>
          <%= if is_map(value) and @depth < @max_depth do %>
            <.tree_node data={value} depth={@depth + 1} max_depth={@max_depth} />
          <% else %>
            <span class="text-gray-700 ml-2"><%= format_value(value) %></span>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp tree_node(%{data: data} = assigns) when is_list(data) do
    ~H"""
    <span class="text-gray-700">[<%= length(@data) %> items]</span>
    """
  end

  defp tree_node(assigns) do
    ~H"""
    <span class="text-gray-700"><%= format_value(@data) %></span>
    """
  end

  defp format_value(value) when is_binary(value), do: "\"#{value}\""
  defp format_value(value) when is_number(value), do: to_string(value)
  defp format_value(value) when is_boolean(value), do: to_string(value)
  defp format_value(value) when is_nil(value), do: "null"
  defp format_value(value) when is_list(value), do: "[#{length(value)} items]"
  defp format_value(value) when is_map(value), do: "{...}"
  defp format_value(value), do: inspect(value)
end

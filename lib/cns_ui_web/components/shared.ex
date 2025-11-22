defmodule CnsUiWeb.Components.Shared do
  @moduledoc """
  Shared UI primitives for overlay dashboards and downstream CNS surfaces.
  """
  use Phoenix.Component

  attr :name, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def icon(assigns) do
    {style, icon_name} = parse_icon(assigns.name)
    icon_assigns = icon_assigns(assigns, style)

    assigns =
      assigns
      |> assign(:icon_name, icon_name)
      |> assign(:icon_assigns, icon_assigns)

    ~H"""
    <%= apply(Heroicons, @icon_name, [@icon_assigns]) %>
    """
  end

  @doc """
  Renders a compact stat card with optional hint and icon.
  """
  attr :title, :string, required: true
  attr :value, :any, required: true
  attr :hint, :string, default: nil
  attr :icon, :string, default: nil
  attr :tone, :atom, default: :default, values: [:default, :success, :warning, :danger]

  def stat_card(assigns) do
    ~H"""
    <div class={[
      "bg-white shadow rounded-lg p-5 flex items-start justify-between gap-4 border border-zinc-100",
      card_border(@tone)
    ]}>
      <div>
        <p class="text-xs font-medium text-zinc-500 uppercase tracking-wide"><%= @title %></p>
        <p class="mt-2 text-2xl font-semibold text-zinc-900"><%= @value %></p>
        <p :if={@hint} class="mt-1 text-xs text-zinc-500"><%= @hint %></p>
      </div>
      <div
        :if={@icon}
        class={[
          "inline-flex items-center justify-center rounded-full p-2",
          icon_bg(@tone)
        ]}
      >
        <.icon name={@icon} class="h-5 w-5 text-zinc-600" />
      </div>
    </div>
    """
  end

  @doc """
  Status badge for overlay health or route readiness.
  """
  attr :status, :string, required: true
  attr :label, :string, default: nil

  def status_badge(assigns) do
    status = assigns.status |> to_string() |> String.downcase()

    assigns =
      assigns
      |> assign(:status, status)
      |> assign_new(:label, fn -> String.capitalize(status) end)

    ~H"""
    <span class={[
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
      badge_colors(@status)
    ]}>
      <%= @label %>
    </span>
    """
  end

  defp card_border(:success), do: "border-emerald-100"
  defp card_border(:warning), do: "border-amber-100"
  defp card_border(:danger), do: "border-rose-100"
  defp card_border(:default), do: "border-transparent"

  defp icon_bg(:success), do: "bg-emerald-50 text-emerald-700"
  defp icon_bg(:warning), do: "bg-amber-50 text-amber-700"
  defp icon_bg(:danger), do: "bg-rose-50 text-rose-700"
  defp icon_bg(:default), do: "bg-zinc-50 text-zinc-700"

  defp badge_colors("healthy"), do: "bg-emerald-100 text-emerald-800"
  defp badge_colors("degraded"), do: "bg-amber-100 text-amber-800"
  defp badge_colors("offline"), do: "bg-rose-100 text-rose-800"
  defp badge_colors("pending"), do: "bg-blue-100 text-blue-800"
  defp badge_colors(_), do: "bg-zinc-100 text-zinc-700"

  defp parse_icon("hero-" <> rest) do
    cond do
      String.ends_with?(rest, "-mini") -> {:mini, rest |> String.replace_suffix("-mini", "")}
      String.ends_with?(rest, "-micro") -> {:micro, rest |> String.replace_suffix("-micro", "")}
      String.ends_with?(rest, "-solid") -> {:solid, rest |> String.replace_suffix("-solid", "")}
      true -> {:outline, rest}
    end
    |> then(fn {style, name} ->
      {style, name |> String.replace("-", "_") |> String.to_existing_atom()}
    end)
  end

  defp parse_icon(name) do
    {:outline, name |> String.replace("-", "_") |> String.to_existing_atom()}
  end

  defp icon_assigns(assigns, style) do
    rest =
      assigns
      |> Map.get(:rest, %{})
      |> Map.put(:class, icon_class(assigns.class))

    %{
      rest: rest,
      solid: style == :solid,
      mini: style == :mini,
      micro: style == :micro,
      outline: style == :outline
    }
  end

  defp icon_class(nil), do: "h-5 w-5"
  defp icon_class(class), do: Enum.join(["h-5 w-5", class], " ")
end

defmodule CrucibleUIWeb.Components do
  @moduledoc """
  Shared Crucible UI components (vendored for CNS UI until packaged).

  These mirror Crucible UI styling so CNS UI can remain a thin shell over
  the shared design system.
  """

  use Phoenix.Component

  @tones %{
    "emerald" => "text-emerald-700 bg-emerald-50",
    "blue" => "text-blue-700 bg-blue-50",
    "amber" => "text-amber-700 bg-amber-50",
    "purple" => "text-purple-700 bg-purple-50",
    "slate" => "text-slate-700 bg-slate-50"
  }

  @doc """
  Single stat card with optional delta and hint text.
  """
  attr :title, :string, required: true
  attr :value, :any, required: true
  attr :delta, :string, default: nil
  attr :hint, :string, default: nil
  attr :tone, :string, default: "slate"

  slot :extra

  def stat_card(assigns) do
    tone_classes = Map.get(@tones, assigns.tone, @tones["slate"])
    assigns = assign(assigns, :tone_classes, tone_classes)

    ~H"""
    <div class="rounded-xl border border-slate-200 p-4 shadow-sm bg-white">
      <p class="text-xs uppercase tracking-wide text-slate-500 mb-1"><%= @title %></p>
      <div class="flex items-baseline justify-between gap-3">
        <div>
          <p class="text-2xl font-semibold text-slate-900"><%= @value %></p>
          <p :if={@hint} class="text-xs text-slate-500 mt-1"><%= @hint %></p>
        </div>
        <span :if={@delta} class={"text-xs px-2 py-1 rounded-lg font-medium #{@tone_classes}"}>
          <%= @delta %>
        </span>
      </div>
      <div :if={render_slot(@extra) != []} class="mt-3">
        <%= render_slot(@extra) %>
      </div>
    </div>
    """
  end

  @doc """
  Progress bar with labeled percentage.
  """
  attr :label, :string, required: true
  attr :percent, :float, default: 0.0
  attr :tone, :string, default: "emerald"
  attr :value, :string, default: nil

  def progress_bar(assigns) do
    tone = Map.get(@tones, assigns.tone, @tones["emerald"])
    percent = assigns.percent |> clamp() |> Float.round(1)

    bg_shade =
      tone
      |> String.split()
      |> Enum.find(fn class -> String.starts_with?(class, "text-") end)
      |> case do
        nil -> "bg-slate-500"
        text_class -> String.replace(text_class, "text-", "bg-")
      end

    assigns =
      assigns
      |> assign(:tone_classes, tone)
      |> assign(:percent_value, percent)
      |> assign(:bg_shade, bg_shade)

    ~H"""
    <div class="space-y-1">
      <div class="flex justify-between text-xs text-slate-600">
        <span><%= @label %></span>
        <span><%= @value || "#{@percent_value}%" %></span>
      </div>
      <div class="h-2 w-full rounded-full bg-slate-100 overflow-hidden">
        <div class={"h-2 #{@bg_shade}"} style={"width: #{@percent_value}%"} />
      </div>
    </div>
    """
  end

  defp clamp(value) when is_number(value) do
    value |> max(0) |> min(100)
  end

  defp clamp(_), do: 0
end

defmodule Tai.IEx.Commands.Orders do
  @moduledoc """
  Display the list of orders and their details
  """

  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Credential",
    "Product Symbol",
    "Product Type",
    "Side",
    "Type",
    "Price",
    "Qty",
    "Leaves Qty",
    "Cumulative Qty",
    "Time in Force",
    "Status",
    "Client ID",
    "Venue Order ID",
    "Enqueued At",
    "Last Received At",
    "Last Venue Timestamp",
    "Updated At",
    "Error Reason"
  ]

  @spec orders :: no_return
  def orders do
    Tai.Commander.orders()
    |> Enum.map(fn order ->
      [
        order.venue_id,
        order.credential_id,
        order.product_symbol,
        order.product_type,
        order.side,
        order.type,
        order.price,
        order.qty,
        order.leaves_qty,
        order.cumulative_qty,
        order.time_in_force,
        order.status,
        order.client_id |> trunc_id(),
        order.venue_order_id && order.venue_order_id |> trunc_id(),
        Timex.from_now(order.enqueued_at),
        order.last_received_at && Timex.from_now(order.last_received_at),
        order.last_venue_timestamp && Timex.from_now(order.last_venue_timestamp),
        order.updated_at && Timex.from_now(order.updated_at),
        order.error_reason && inspect(order.error_reason)
      ]
    end)
    |> render!(@header)
  end

  defp trunc_id(val), do: "#{val |> String.slice(0..5)}..."
end

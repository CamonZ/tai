defmodule Tai.Trading.Orders.CancelTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  alias Tai.Trading.{Order, Orders, OrderSubmissions}
  alias Tai.TestSupport.Mocks

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})
  @submission_attrs %{venue_id: @venue, credential_id: @credential}

  setup do
    start_supervised!(Mocks.Server)
    start_supervised!({TaiEvents, 1})
    start_supervised!({Tai.Settings, Tai.Config.parse()})
    start_supervised!(Tai.Trading.OrderStore)
    start_supervised!(Tai.Venues.VenueStore)

    mock_venue(id: @venue, credentials: @credentials, adapter: Tai.VenueAdapters.Mock)

    :ok
  end

  [
    {:buy, OrderSubmissions.BuyLimitGtc},
    {:sell, OrderSubmissions.SellLimitGtc}
  ]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} cancels the order on the venue" do
      submission =
        Support.OrderSubmissions.build_with_callback(@submission_type, @submission_attrs)

      Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)

      {:ok, order} = Orders.create(submission)
      assert_receive {:callback_fired, %Order{status: :enqueued}, %Order{status: :open}}

      Mocks.Responses.Orders.GoodTillCancel.canceled(@venue_order_id)
      assert {:ok, %Order{status: :pending_cancel}} = Orders.cancel(order)
      assert_receive {:callback_fired, %Order{status: :open}, %Order{status: :pending_cancel}}
      assert_receive {:callback_fired, %Order{status: :pending_cancel}, %Order{status: :canceled}}
    end
  end)
end

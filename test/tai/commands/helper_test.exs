require IEx;

defmodule Tai.Commands.HelperTest do
  use ExUnit.Case
  doctest Tai.Commands.Helper

  import ExUnit.CaptureIO

  alias Tai.{Commands.Helper, Markets.OrderBook}

  setup do
    test_feed_a_btcusd = [feed_id: :test_feed_a, symbol: :btcusd] |> OrderBook.to_name
    stop_supervised(test_feed_a_btcusd)

    {:ok, %{test_feed_a_btcusd: test_feed_a_btcusd}}
  end

  test "help returns the usage for the supported commands" do
    assert capture_io(&Helper.help/0) == """
    * balance
    * order_book_status
    * quotes exchange(:gdax), symbol(:btcusd)
    * buy_limit exchange(:gdax), symbol(:btcusd), price(101.12), size(1.2)
    * sell_limit exchange(:gdax), symbol(:btcusd), price(101.12), size(1.2)
    * order_status exchange(:gdax), order_id("f1bb2fa3-6218-45be-8691-21b98157f25a")
    * cancel_order exchange(:gdax), order_id("f1bb2fa3-6218-45be-8691-21b98157f25a")\n
    """
  end

  test "balance is the sum of USD balances across accounts" do
    assert capture_io(fn -> Helper.balance end) == "0.22 USD\n"
  end

  test "order_book_status displays all inside quotes and the time they were last processed and changed", %{test_feed_a_btcusd: test_feed_a_btcusd} do
    :ok = OrderBook.replace(
      test_feed_a_btcusd,
      %{
        bids: %{
          12999.99 => {0.000021, nil, nil},
          12999.98 => {1.0, nil, nil}
        },
        asks: %{
          13000.01 => {1.11, nil, nil},
          13000.02 => {1.25, nil, nil}
        }
      }
    )

    assert capture_io(fn -> Helper.order_book_status() end) == """
    +-------------+--------+-----------+-----------+----------+----------+-------------------+-----------------+
    |        Feed | Symbol | Bid Price | Ask Price | Bid Size | Ask Size | Last Processed At | Last Changed At |
    +-------------+--------+-----------+-----------+----------+----------+-------------------+-----------------+
    | test_feed_a | btcusd |  12999.99 |  13000.01 | 0.000021 |     1.11 |                   |                 |
    | test_feed_a | ltcusd |         0 |         0 |        0 |        0 |                   |                 |
    | test_feed_b | ethusd |         0 |         0 |        0 |        0 |                   |                 |
    | test_feed_b | ltcusd |         0 |         0 |        0 |        0 |                   |                 |
    +-------------+--------+-----------+-----------+----------+----------+-------------------+-----------------+\n
    """
  end

  test "quotes shows the snapshot of the live order book", %{test_feed_a_btcusd: test_feed_a_btcusd} do
    :ok = OrderBook.replace(
      test_feed_a_btcusd,
      %{
        bids: %{
          12999.99 => {0.000021, nil, nil},
          12999.98 => {1.0, nil, nil}
        },
        asks: %{
          13000.01 => {1.11, nil, nil},
          13000.02 => {1.25, nil, nil}
        }
      }
    )

    assert capture_io(fn -> Helper.quotes(feed_id: :test_feed_a, symbol: :btcusd) end) == """
    13000.01/1.11
    ---
    12999.99/0.000021\n
    """
  end

  # TODO: Figure out how to trap calls to process with name that doesn't exist
  @tag :skip
  test "quotes with remote displays errors from the server" do
    assert capture_io(fn ->
      Helper.quotes(feed_id: :test_exchange_a, symbol: :notfound)
    end) == "error: NotFound\n"
  end

  test "buy_limit creates an order on the exchange then displays it's 'id' and 'status'" do
    assert capture_io(fn ->
      Helper.buy_limit(:test_exchange_a, :btcusd, 10.1, 2.2)
    end) == "create order success - id: f9df7435-34d5-4861-8ddc-80f0fd2c83d7, status: pending\n"
  end

  test "buy_limit displays an error message when the order can't be created" do
    assert capture_io(fn ->
      Helper.buy_limit(:test_exchange_a, :btcusd, 10.1, 3.3)
    end) == "create order failure - Insufficient funds\n"
  end

  test "sell_limit creates an order on the exchange then displays it's 'id' and 'status'" do
    assert capture_io(fn ->
      Helper.sell_limit(:test_exchange_a, :btcusd, 10.1, 2.2)
    end) == "create order success - id: 41541912-ebc1-4173-afa5-4334ccf7a1a8, status: pending\n"
  end

  test "sell_limit displays an error message when the order can't be created" do
    assert capture_io(fn ->
      Helper.sell_limit(:test_exchange_a, :btcusd, 10.1, 3.3)
    end) == "create order failure - Insufficient funds\n"
  end

  test "order_status displays the order info" do
    assert capture_io(fn ->
      Helper.order_status(:test_exchange_a, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7")
    end) == "status: open\n"
  end

  test "order_status displays error messages" do
    assert capture_io(fn ->
      Helper.order_status(:test_exchange_a, "invalid-order-id")
    end) == "error: Invalid order id\n"
  end

  test "cancel_order cancels a previous order" do
    assert capture_io(fn ->
      Helper.cancel_order(:test_exchange_a, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7")
    end) == "cancel order success\n"
  end

  test "cancel_order displays error messages" do
    assert capture_io(fn ->
      Helper.cancel_order(:test_exchange_a, "invalid-order-id")
    end) == "error: Invalid order id\n"
  end
end
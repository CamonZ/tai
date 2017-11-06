defmodule Tai.VenueAdapters.Bitmex.Products do
  require Logger

  def products(venue_id) do
    with {:ok, response} <-
           Bitmex.Rest.Client.non_auth_get("/instrument", %{start: 0, count: 500}) do
      products = Enum.map(response.body, &build(&1, venue_id))

      {:ok, products}
    else
      {:error, %HTTPoison.Error{id: nil, reason: "timeout"}} ->
        {:error, %Tai.TimeoutError{}}
    end
  end

  defp build(
         %{
           "symbol" => bitmex_symbol,
           "state" => state,
           "lotSize" => lot_size,
           "tickSize" => tick_size,
           "maxOrderQty" => max_order_qty,
           "maxPrice" => max_price,
           "makerFee" => maker_fee,
           "takerFee" => taker_fee
         },
         venue_id
       ) do
    symbol = bitmex_symbol |> String.downcase() |> String.to_atom()
    status = Tai.VenueAdapters.Bitmex.ProductStatus.normalize(state)

    %Tai.Exchanges.Product{
      exchange_id: venue_id,
      symbol: symbol,
      exchange_symbol: bitmex_symbol,
      status: status,
      min_size: lot_size && lot_size |> Decimal.new(),
      price_increment: tick_size |> Decimal.new(),
      max_price: max_price && max_price |> Decimal.new(),
      max_size: max_order_qty && max_order_qty |> Decimal.new(),
      size_increment: tick_size |> Decimal.new(),
      maker_fee: maker_fee && maker_fee |> Decimal.new(),
      taker_fee: maker_fee && taker_fee |> Decimal.new()
    }
  end
end

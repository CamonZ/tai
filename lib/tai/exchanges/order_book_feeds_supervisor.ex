defmodule Tai.Exchanges.OrderBookFeedsSupervisor do
  use DynamicSupervisor

  @type product :: Tai.Exchanges.Product.t()
  @type null_feed :: Tai.Venues.NullOrderBookFeed

  def start_link(_), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  @spec start_feed(
          adapter :: Tai.Exchanges.Adapter.t() | null_feed,
          products :: [product]
        ) :: DynamicSupervisor.on_start_child()
  def start_feed(Tai.Venues.NullOrderBookFeed, _), do: :ignore

  def start_feed(adapter, products) do
    spec = {Tai.Exchanges.OrderBookFeedSupervisor, [adapter: adapter, trading_products: products]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end

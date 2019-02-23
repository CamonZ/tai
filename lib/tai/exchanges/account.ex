defmodule Tai.Exchanges.Account do
  @moduledoc """
  Uniform interface for private exchange actions
  """

  @type t :: %Tai.Exchanges.Account{
          exchange_id: atom,
          account_id: atom
        }
  @type order :: Tai.Trading.Order.t()
  @type order_status :: Tai.Trading.Order.status()
  @type venue_order_id :: Tai.Trading.Order.venue_order_id()
  @type order_response :: Tai.Trading.OrderResponse.t()
  @type credentials :: map
  @type time_in_force :: Tai.Trading.Order.time_in_force()
  @type shared_error_reason ::
          :timeout
          | {:credentials, reason :: term}
  @type create_order_error_reason ::
          :not_implemented
          | {:insufficient_balance, reason :: term}
          | shared_error_reason

  @callback create_order(order, credentials) ::
              {:ok, order_response} | {:error, create_order_error_reason}

  @callback cancel_order(venue_order_id, credentials) ::
              {:ok, venue_order_id} | {:error, :not_implemented | (reason :: term)}

  @callback order_status(venue_order_id, credentials) ::
              {:ok, order_status} | {:error, :not_implemented | (reason :: term)}

  @enforce_keys [:exchange_id, :account_id, :credentials]
  defstruct [:exchange_id, :account_id, :credentials]

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer

      @behaviour Tai.Exchanges.Account

      def start_link(exchange_id: exchange_id, account_id: account_id, credentials: credentials) do
        name = Tai.Exchanges.Account.to_name(exchange_id, account_id)

        account = %Tai.Exchanges.Account{
          exchange_id: exchange_id,
          account_id: account_id,
          credentials: credentials
        }

        GenServer.start_link(__MODULE__, account, name: name)
      end

      def init(state) do
        {:ok, state}
      end

      def handle_call({:create_order, order}, _from, state) do
        response = create_order(order, state.credentials)
        {:reply, response, state}
      end

      def handle_call({:amend_order, order, attrs}, _from, state) do
        response = amend_order(order.venue_order_id, attrs, state.credentials)
        {:reply, response, state}
      end

      def handle_call({:cancel_order, venue_order_id}, _from, state) do
        response = cancel_order(venue_order_id, state)
        {:reply, response, state}
      end

      def handle_call({:order_status, venue_order_id}, _from, state) do
        response = order_status(venue_order_id, state.credentials)
        {:reply, response, state}
      end
    end
  end

  @spec create_order(order) :: {:ok, order_response} | {:error, create_order_error_reason}
  def create_order(%Tai.Trading.Order{} = order) do
    server = to_name(order.exchange_id, order.account_id)
    GenServer.call(server, {:create_order, order})
  end

  @spec amend_order(order, map) :: {:ok, order} | {:error, reason :: term}
  def amend_order(%Tai.Trading.Order{} = order, attrs) do
    server = to_name(order.exchange_id, order.account_id)
    GenServer.call(server, {:amend_order, order, attrs})
  end

  @spec order_status(atom, atom, venue_order_id) :: {:ok, order_status} | {:error, reason :: term}
  def order_status(venue_id, account_id, venue_order_id) do
    server = to_name(venue_id, account_id)
    GenServer.call(server, {:order_status, venue_order_id})
  end

  @spec cancel_order(atom, atom, venue_order_id) ::
          {:ok, venue_order_id} | {:error, reason :: term}
  def cancel_order(venue_id, account_id, venue_order_id) do
    server = to_name(venue_id, account_id)
    GenServer.call(server, {:cancel_order, venue_order_id})
  end

  @spec to_name(atom, atom) :: atom
  def to_name(exchange_id, account_id),
    do: :"#{Tai.Exchanges.Account}_#{exchange_id}_#{account_id}"
end

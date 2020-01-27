defmodule Tai.ConfigTest do
  use ExUnit.Case, async: true
  doctest Tai.Config

  describe ".parse" do
    test "returns a default representation" do
      schedulers_online = System.schedulers_online()

      assert %Tai.Config{
               send_orders: false,
               venue_boot_handler: Tai.Venues.BootHandler,
               venues: %{},
               advisor_groups: %{},
               adapter_timeout: 10_000,
               broadcast_change_set: false,
               event_registry_partitions: ^schedulers_online,
               pub_sub_registry_partitions: ^schedulers_online
             } = Tai.Config.parse([])
    end

    test "can set send_orders" do
      assert config = Tai.Config.parse(send_orders: true)
      assert config.send_orders == true
    end

    test "can set adapter_timeout" do
      assert config = Tai.Config.parse(adapter_timeout: 5000)
      assert config.adapter_timeout == 5000
    end

    test "can set event_registry_partitions" do
      assert config = Tai.Config.parse(event_registry_partitions: 1)
      assert config.event_registry_partitions == 1
    end

    test "can set venue_boot_handler" do
      assert config = Tai.Config.parse(venue_boot_handler: MyBootHandler)
      assert config.venue_boot_handler == MyBootHandler
    end

    test "can set venues" do
      assert config = Tai.Config.parse(venues: :venues)
      assert config.venues == :venues
    end

    test "can set advisor_groups" do
      assert config = Tai.Config.parse(advisor_groups: :advisor_groups)
      assert config.advisor_groups == :advisor_groups
    end

    test "can set broadcast_change_set" do
      assert config = Tai.Config.parse(broadcast_change_set: true)
      assert config.broadcast_change_set
    end
  end
end

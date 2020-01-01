defmodule Tai.Venues.Adapters.Gdax.AssetBalancesTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters()

  setup_all do
    HTTPoison.start()
    adapter = @test_adapters |> Map.fetch!(:gdax)
    {:ok, %{adapter: adapter}}
  end

  test "returns an error tuple when the passphrase is invalid", %{adapter: adapter} do
    use_cassette "venue_adapters/shared/asset_balances/gdax/error_invalid_passphrase" do
      assert {:error, {:credentials, reason}} = Tai.Venues.Client.asset_balances(adapter, :main)
      assert reason == "Invalid Passphrase"
    end
  end

  test "returns an error tuple when the api key is invalid", %{adapter: adapter} do
    use_cassette "venue_adapters/shared/asset_balances/gdax/error_invalid_api_key" do
      assert {:error, {:credentials, reason}} = Tai.Venues.Client.asset_balances(adapter, :main)
      assert reason == "Invalid API Key"
    end
  end

  test "returns an error tuple when down for maintenance", %{adapter: adapter} do
    use_cassette "venue_adapters/shared/asset_balances/gdax/error_maintenance" do
      assert {:error, reason} = Tai.Venues.Client.asset_balances(adapter, :main)

      assert reason ==
               {:service_unavailable,
                "GDAX is currently under maintenance. For updates please see https://status.gdax.com/"}
    end
  end
end

defmodule Riot.LoR.FactionTest do
  alias Riot.LoR.Faction

  use ExUnit.Case

  doctest Faction

  describe "guards" do
    test "is_version" do
      Enum.each(Faction.versions(), fn input ->
        assert Faction.is_version(input)
      end)
    end

    test "is_id" do
      Enum.each(Faction.ids(), fn input ->
        assert Faction.is_id(input)
      end)
    end

    test "is_code" do
      Enum.each(Faction.codes(), fn input ->
        assert Faction.is_code(input)
      end)
    end
  end

  describe "attributes" do
    test "versions" do
      assert Faction.versions() == 1..5
    end

    test "ids" do
      assert Faction.ids() == [0, 1, 2, 3, 4, 5, 6, 9, 7, 10, 12]
    end

    test "codes" do
      assert Faction.codes() == ["DE", "FR", "IO", "NX", "PZ", "SI", "BW", "MT", "SH", "BC", "RU"]
    end

    test "min_version" do
      assert Faction.min_version() == 1
    end

    test "max_version" do
      assert Faction.max_version() == 5
    end
  end

  test "fetch_by_id!" do
    Enum.each(Faction.ids(), fn input ->
      {_v, actual_id, _code} = Faction.fetch_by_id!(input)
      assert actual_id == input
    end)
  end

  test "fetch_by_code!" do
    Enum.each(Faction.codes(), fn input ->
      {_v, _i, actual_code} = Faction.fetch_by_code!(input)
      assert actual_code == input
    end)
  end
end

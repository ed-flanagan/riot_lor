defmodule Riot.LoR.FactionTest do
  alias Riot.LoR.Faction

  use ExUnit.Case

  doctest Faction

  @known_versions [1, 2, 3, 4]
  # NOTE: no 8
  @known_ids [0, 1, 2, 3, 4, 5, 6, 7, 9, 10]
  @known_codes ["DE", "FR", "IO", "NX", "PZ", "SI", "BW", "MT", "SH", "BC"]

  describe "guards" do
    test "is_version" do
      Enum.each(@known_versions, fn input ->
        assert Faction.is_version(input)
      end)
    end

    test "is_id" do
      Enum.each(@known_ids, fn input ->
        assert Faction.is_id(input)
      end)
    end

    test "is_code" do
      Enum.each(@known_codes, fn input ->
        assert Faction.is_code(input)
      end)
    end
  end

  test "fetch_by_id!" do
    Enum.each(@known_ids, fn input ->
      {_v, actual_id, _code} = Faction.fetch_by_id!(input)
      assert actual_id == input
    end)
  end

  test "fetch_by_code!" do
    Enum.each(@known_codes, fn input ->
      {_v, _i, actual_code} = Faction.fetch_by_code!(input)
      assert actual_code == input
    end)
  end

  test "min_version" do
    assert Faction.min_version() == Enum.min(@known_versions)
  end

  test "max_version" do
    assert Faction.max_version() == Enum.max(@known_versions)
  end
end

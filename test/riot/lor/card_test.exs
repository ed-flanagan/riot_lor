defmodule Riot.LoR.CardTest do
  alias Riot.LoR.Card

  use ExUnit.Case
  use ExUnitProperties

  doctest Card

  @known_valid_card_facs [0, 1, 2, 3, 4, 5, 6, 7, 9, 10]
  @known_valid_card_nums 1..999
  @known_valid_card_sets 1..99

  describe "guards" do
    property "is_card_num" do
      check all int <- integer(@known_valid_card_nums) do
        assert Card.is_card_num(int)
      end
    end

    property "is_card_set" do
      check all int <- integer(@known_valid_card_sets) do
        assert Card.is_card_set(int)
      end
    end
  end

  describe "struct" do
    test "new" do
      [
        {{1, 0, 1}, %Card{set: 1, fac: 0, num: 1}},
        {{2, 0, 1}, %Card{set: 2, fac: 0, num: 1}},
        {{3, 0, 1}, %Card{set: 3, fac: 0, num: 1}},
        {{4, 0, 1}, %Card{set: 4, fac: 0, num: 1}},
        {{5, 4, 6}, %Card{set: 5, fac: 4, num: 6}},
        {{5, 10, 198}, %Card{set: 5, fac: 10, num: 198}}
      ]
      |> Enum.each(fn {input, expected} ->
        assert Card.new(input) == expected
      end)
    end

    property "new" do
      sets = StreamData.member_of(@known_valid_card_sets)
      facs = StreamData.member_of(@known_valid_card_facs)
      nums = StreamData.integer(@known_valid_card_nums)

      check all {s, f, n} = tup <- tuple({sets, facs, nums}) do
        assert Card.new(tup) == %Card{set: s, fac: f, num: n}
      end
    end
  end

  describe "parse" do
    test "valid deck code" do
      [
        {"01DE001", %Card{set: 1, fac: 0, num: 1}},
        {"02DE001", %Card{set: 2, fac: 0, num: 1}},
        {"03DE001", %Card{set: 3, fac: 0, num: 1}},
        {"04DE001", %Card{set: 4, fac: 0, num: 1}},
        {"05PZ006", %Card{set: 5, fac: 4, num: 6}},
        {"05BC198", %Card{set: 5, fac: 10, num: 198}}
      ]
      |> Enum.each(fn {input, expected} ->
        assert Card.parse!(input) == expected
      end)
    end

    test "invalid deck code: non-matching" do
      # These strings won't match parse!/1
      [
        "",
        "01",
        "01DE",
        "01DE1",
        "01DE01",
        "01DE-9",
        "01DE0001",
        "01DE1000"
      ]
      |> Enum.each(fn input ->
        assert_raise FunctionClauseError, fn ->
          Card.parse!(input)
        end
      end)
    end

    test "invalid deck code: matching, new/1 fails" do
      # These strings will match parse!/1, but not new/1
      [
        "01DE-01",
        "01DE-99"
      ]
      |> Enum.each(fn input ->
        assert_raise FunctionClauseError, fn ->
          Card.parse!(input)
        end
      end)
    end
  end

  test "to_code!" do
    [
      {%Card{set: 1, fac: 0, num: 1}, "01DE001"},
      {%Card{set: 2, fac: 0, num: 1}, "02DE001"},
      {%Card{set: 3, fac: 0, num: 1}, "03DE001"},
      {%Card{set: 4, fac: 0, num: 1}, "04DE001"},
      {%Card{set: 5, fac: 4, num: 6}, "05PZ006"},
      {%Card{set: 5, fac: 10, num: 198}, "05BC198"}
    ]
    |> Enum.each(fn {input, expected} ->
      assert Card.to_code!(input) == expected
    end)
  end

  property "new and as_tuple is circular" do
    sets = StreamData.member_of(@known_valid_card_sets)
    facs = StreamData.member_of(@known_valid_card_facs)
    nums = StreamData.integer(@known_valid_card_nums)

    check all tup <- tuple({sets, facs, nums}) do
      result =
        tup
        |> Card.new()
        |> Card.as_tuple()

      assert result == tup
    end
  end
end

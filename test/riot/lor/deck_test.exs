defmodule Riot.LoR.DeckTest do
  alias Riot.LoR.Card
  alias Riot.LoR.Deck
  alias Riot.LoR.Faction

  use ExUnit.Case
  use ExUnitProperties

  doctest Deck

  describe "new" do
    test "empty deck" do
      assert Deck.new() == %{}
    end

    test "non-empty deck" do
      [
        {
          [
            {"01DE001", 3},
            {"02DE001", 1},
            {"03DE001", 4}
          ],
          %{
            %Card{set: 3, fac: 0, num: 1} => 4,
            %Card{set: 1, fac: 0, num: 1} => 3,
            %Card{set: 2, fac: 0, num: 1} => 1
          }
        }
      ]
      |> Enum.each(fn {input, expected} ->
        assert Deck.from_card_counts!(input) == expected
      end)
    end
  end

  describe "add_card" do
    test "valid" do
      deck = Deck.new()

      default_stages = [
        {%Card{set: 1, fac: 0, num: 1}, %{%Card{set: 1, fac: 0, num: 1} => 1}},
        {%Card{set: 1, fac: 0, num: 1}, %{%Card{set: 1, fac: 0, num: 1} => 2}},
        {%Card{set: 1, fac: 0, num: 1}, %{%Card{set: 1, fac: 0, num: 1} => 3}},
        {%Card{set: 2, fac: 0, num: 1},
         %{%Card{set: 1, fac: 0, num: 1} => 3, %Card{set: 2, fac: 0, num: 1} => 1}}
      ]

      deck =
        Enum.reduce(default_stages, deck, fn {card, expected}, deck ->
          deck = Deck.add_card(deck, card)
          assert deck == expected
          deck
        end)

      explicit_stages = [
        {{%Card{set: 3, fac: 0, num: 1}, 4},
         %{
           %Card{set: 1, fac: 0, num: 1} => 3,
           %Card{set: 2, fac: 0, num: 1} => 1,
           %Card{set: 3, fac: 0, num: 1} => 4
         }}
      ]

      Enum.reduce(explicit_stages, deck, fn {{card, count}, expected}, deck ->
        deck = Deck.add_card(deck, card, count)
        assert deck == expected
        deck
      end)
    end

    test "invalid" do
      deck = Deck.new()
      card = %Card{set: 1, fac: 0, num: 1}

      assert_raise FunctionClauseError, fn -> Deck.add_card(deck, card, -1) end
    end
  end

  describe "add_card_code!" do
    test "valid" do
      deck = Deck.new()

      deck = Deck.add_card_code!(deck, "01DE001")
      assert deck == %{%Card{set: 1, fac: 0, num: 1} => 1}

      deck = Deck.add_card_code!(deck, "01DE001", 2)
      assert deck == %{%Card{set: 1, fac: 0, num: 1} => 3}
    end

    test "invalid" do
      deck = Deck.new()
      ok_card_code = "01DE001"
      bad_card_code = "00AA001"

      assert_raise FunctionClauseError, fn -> Deck.add_card_code!(deck, ok_card_code, -1) end
      assert_raise FunctionClauseError, fn -> Deck.add_card_code!(deck, bad_card_code) end
    end
  end

  describe "remove_card" do
    test "stages" do
      deck = %{
        %Card{set: 1, fac: 0, num: 1} => 3,
        %Card{set: 2, fac: 0, num: 1} => 1,
        %Card{set: 3, fac: 0, num: 1} => 4
      }

      stages = [
        {{%Card{set: 3, fac: 0, num: 1}, nil},
         %{
           %Card{set: 1, fac: 0, num: 1} => 3,
           %Card{set: 2, fac: 0, num: 1} => 1,
           %Card{set: 3, fac: 0, num: 1} => 3
         }},
        {{%Card{set: 2, fac: 0, num: 1}, nil},
         %{%Card{set: 1, fac: 0, num: 1} => 3, %Card{set: 3, fac: 0, num: 1} => 3}},
        {{%Card{set: 1, fac: 0, num: 1}, 2},
         %{%Card{set: 1, fac: 0, num: 1} => 1, %Card{set: 3, fac: 0, num: 1} => 3}},
        {{%Card{set: 3, fac: 0, num: 1}, :all}, %{%Card{set: 1, fac: 0, num: 1} => 1}}
      ]

      Enum.reduce(stages, deck, fn {{card, count}, expected}, deck ->
        deck =
          if count == nil do
            Deck.remove_card(deck, card)
          else
            Deck.remove_card(deck, card, count)
          end

        assert deck == expected
        deck
      end)
    end

    test "doesn't exist" do
      expected = %{
        %Card{set: 1, fac: 0, num: 1} => 1
      }

      deck = Deck.remove_card(expected, %Card{set: 1, fac: 0, num: 2})
      assert deck == expected
    end
  end

  test "min_required_verison" do
    deck = Deck.new()
    assert Deck.min_required_version(deck) == Faction.min_version()

    deck = Deck.add_card(deck, %Card{set: 1, fac: 0, num: 1})
    assert Deck.min_required_version(deck) == 1

    deck = Deck.add_card(deck, %Card{set: 5, fac: 10, num: 198})
    assert Deck.min_required_version(deck) == 4
  end

  test "code_count" do
    [
      {
        %{
          %Card{set: 3, fac: 0, num: 1} => 4,
          %Card{set: 1, fac: 0, num: 1} => 3,
          %Card{set: 2, fac: 0, num: 1} => 1
        },
        [
          {"01DE001", 3},
          {"02DE001", 1},
          {"03DE001", 4}
        ]
      }
    ]
    |> Enum.each(fn {input, expected} ->
      assert Deck.code_count(input) == expected
    end)
  end

  # TODO: property: new & code_count are cyclical
end

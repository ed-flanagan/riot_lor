defmodule Riot.LoR.DeckCodeTest do
  alias Riot.LoR.Card
  alias Riot.LoR.DeckCode

  use ExUnit.Case
  use ExUnitProperties

  doctest DeckCode

  @known_valid_card_facs [0, 1, 2, 3, 4, 5, 6, 7, 9, 10]
  @known_valid_card_nums 1..999
  @known_valid_card_sets 1..99

  setup_all do
    %{
      valid: valid_deck_code_examples()
    }
  end

  describe "decode" do
    test "valid", %{valid: decks} do
      Enum.each(decks, fn {deck_code, expected} ->
        assert DeckCode.decode!(deck_code) == expected
      end)
    end

    test "invalid version" do
      [
        # Version 5
        # Manually generate:
        # <<1 <<< 4 ||| 5>> <> Enum.into([0, 0, 1, 1, 5, 0, 1], <<>>, &Riot.Util.Varint.LEB128.encode/1)
        # |> Base.encode32(padding: false)
        "CUAAAAIBAUAAC"
      ]
      |> Enum.each(fn input ->
        assert_raise FunctionClauseError, fn -> DeckCode.decode!(input) end
      end)
    end

    test "invalid format" do
      [
        # Format 2
        # Manually generate:
        # <<2 <<< 4 ||| 5>> <> Enum.into([0, 0, 1, 1, 5, 0, 1], <<>>, &Riot.Util.Varint.LEB128.encode/1)
        # |> Base.encode32(padding: false)
        "EUAAAAIBAUAAC"
      ]
      |> Enum.each(fn input ->
        assert_raise FunctionClauseError, fn -> DeckCode.decode!(input) end
      end)
    end
  end

  describe "encode" do
    test "valid", %{valid: decks} do
      Enum.each(decks, fn {expected, deck} ->
        assert DeckCode.encode!(deck) == expected
      end)
    end
  end

  describe "encode/decode cycle" do
    property "deck-to-deck encode->decode" do
      sets = @known_valid_card_sets |> StreamData.integer() |> StreamData.unshrinkable()
      facs = @known_valid_card_facs |> StreamData.member_of() |> StreamData.unshrinkable()
      nums = @known_valid_card_nums |> StreamData.integer() |> StreamData.unshrinkable()

      cards =
        {sets, facs, nums}
        |> StreamData.tuple()
        |> StreamData.map(&Card.new/1)

      card_counts = StreamData.positive_integer() |> StreamData.unshrinkable()
      decks = StreamData.map_of(cards, card_counts, max_length: 30)

      check all deck <- decks do
        result =
          deck
          |> DeckCode.encode!()
          |> DeckCode.decode!()

        assert result == deck
      end
    end

    # TODO: property "code-to-code decode->encode"
    # [<format>, <required_version>, Ncount, Cnx_count, set, fac, nums..., Cny_count, set, fac, nums, ..., ...]
  end

  defp valid_deck_code_examples do
    [
      # Empty deck
      {
        "CEAAAAA",
        %{}
      },
      # min/max cards
      {
        "CQAAAAQBAEAACAIFBLDAC",
        %{
          %Card{fac: 0, num: 1, set: 1} => 1,
          %Card{fac: 10, num: 198, set: 5} => 1
        }
      },
      # Sort tests
      {
        "CIAAAAQBAEABMAICAYLA",
        %{
          %Card{fac: 0, num: 22, set: 1} => 1,
          %Card{fac: 6, num: 22, set: 2} => 1
        }
      },
      {
        "CEAAAAQBAEAQCAIBAIAQ",
        %{
          %Card{fac: 1, num: 1, set: 1} => 1,
          %Card{fac: 2, num: 1, set: 1} => 1
        }
      },
      {
        "CIAAAAQBAIDACAICAAAQ",
        %{
          %Card{fac: 0, num: 1, set: 2} => 1,
          %Card{fac: 6, num: 1, set: 2} => 1
        }
      },
      {
        "CIBACAYJGYBACAQIB4AAA",
        %{
          %Card{fac: 2, num: 8, set: 1} => 3,
          %Card{fac: 2, num: 15, set: 1} => 3,
          %Card{fac: 9, num: 54, set: 3} => 3
        }
      },
      {
        "CIBACAICB4BAGCJWLAAAA",
        %{
          %Card{fac: 2, num: 15, set: 1} => 3,
          %Card{fac: 9, num: 54, set: 3} => 3,
          %Card{fac: 9, num: 88, set: 3} => 3
        }
      },
      # Examples from
      # 4+ counts
      {
        "CEAAAAAEAEAAC",
        %{
          %Card{fac: 0, num: 1, set: 1} => 4
        }
      }
    ] ++ read_deck_code_test_file()
  end

  # Examples from
  # https://github.com/RiotGames/LoRDeckCodes/blob/main/LoRDeckCodes_Tests/DeckCodesTestData.txt
  defp read_deck_code_test_file do
    Path.join([__DIR__, "support", "deck_codes.txt"])
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.chunk_while(
      {},
      fn
        # Split on empty line
        "", {code, card_counts} -> {:cont, {code, Enum.reverse(card_counts)}, {}}
        # First line is the deck code
        line, {} -> {:cont, {line, []}}
        # Subsequent lines are card count + count
        line, {code, card_counts} -> {:cont, {code, [line | card_counts]}}
      end,
      fn {code, card_counts} -> {:cont, {code, Enum.reverse(card_counts)}, {}} end
    )
    |> Stream.map(fn {code, card_counts} ->
      cards =
        Enum.into(card_counts, %{}, fn cc ->
          [count, card_code] = String.split(cc, ":")
          {Card.parse!(card_code), String.to_integer(count)}
        end)

      {code, cards}
    end)
    |> Enum.to_list()
  end
end

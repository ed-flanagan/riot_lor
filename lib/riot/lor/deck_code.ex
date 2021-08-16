defmodule Riot.LoR.DeckCode do
  @moduledoc """
  Functions to encode/decode a LoR deck code.
  """

  use Bitwise, only_operators: true

  alias Riot.LoR.Card
  alias Riot.LoR.Deck
  alias Riot.LoR.Faction
  alias Riot.Util.Varint.LEB128

  import Riot.LoR.Faction, only: [is_version: 1]

  ##########
  # Decode #
  ##########

  @doc """
  Takes a deck code and attempts to decode into a `Riot.LoR.Deck`.

  ## Examples

      iex> deck_code = "CEAAAAIBAEAAC"
      iex> Riot.LoR.DeckCode.decode!(deck_code)
      %{%Riot.LoR.Card{fac: 0, num: 1, set: 1} => 1}

  """
  @doc since: "1.0.0"
  @spec decode!(binary) :: Deck.t()
  def decode!(deck_code) when is_binary(deck_code) do
    deck_code
    |> Base.decode32!(case: :mixed, padding: false)
    |> decode_binary!()
  end

  # Implmentation for Format v1
  @spec decode_binary!(binary) :: Deck.t()
  defp decode_binary!(<<1::integer-size(4), version::integer-size(4), cards_varints::bitstring>>)
       when is_version(version) do
    # Decode Varint sequence into a list of integers
    {buf, _leftover, _bytes} = LEB128.decode_all(cards_varints)

    # Add card counts for "primary" quantities, i.e. 1-3
    {deck, buf} =
      Enum.reduce(3..1, {Deck.new(), buf}, fn
        # Skip quantity groups with 0 factions
        _cnt, {deck, [0 | buf]} ->
          {deck, buf}

        cnt, {deck, [num_factions | buf]} ->
          Enum.reduce(1..num_factions, {deck, buf}, fn _, {deck, buf} ->
            [num_cards, set, fac | buf] = buf
            {card_nums, buf} = Enum.split(buf, num_cards)

            deck =
              card_nums
              |> Enum.map(&Card.new({set, fac, &1}))
              |> Enum.reduce(deck, &Deck.add_card(&2, &1, cnt))

            {deck, buf}
          end)
      end)

    # Add card counts for "special" quantities, i.e. 4+
    deck =
      buf
      |> Enum.chunk_every(4, 4, :discard)
      |> Enum.reduce(deck, fn [cnt, set, fac, num], deck ->
        card = Card.new({set, fac, num})
        Deck.add_card(deck, card, cnt)
      end)

    deck
  end

  ##########
  # Encode #
  ##########

  @doc """
  Takes a `Riot.LoR.Deck` and encodes it into a deck code string.

  ## Examples

      iex> deck = Riot.LoR.Deck.new()
      iex> deck = Riot.LoR.Deck.add_card(deck, %Riot.LoR.Card{set: 1, fac: 0, num: 1})
      iex> Riot.LoR.DeckCode.encode!(deck)
      "CEAAAAIBAEAAC"

  """
  @doc since: "1.0.0"
  @spec encode!(Deck.t(), pos_integer) :: binary
  def encode!(deck, format \\ 1)

  # Deck code format 1 implementation
  def encode!(deck, 1 = format) do
    # Resolve the minimum version
    min_version = Deck.min_required_version(deck)

    # Create deck code prefix: format+version
    # NOTE: doesn't ensure low-order bits for either since we trust
    # format and min_version are both < 16
    prefix = <<format <<< 4 ||| min_version>>

    # Split out the "primary" (1-3) counts and "special" (4+) counts
    {primary, special} =
      deck
      |> Enum.group_by(
        fn {_card, quant} -> quant end,
        fn {card, _quant} -> Card.as_tuple(card) end
      )
      |> map_split_default([1, 2, 3], [])

    primary_varints =
      primary
      |> sort_primary_varints()
      |> Enum.into(<<>>, &LEB128.encode/1)

    special_varints =
      special
      |> sort_special_varints()
      |> Enum.into(<<>>, &LEB128.encode/1)

    raw = prefix <> primary_varints <> special_varints
    Base.encode32(raw, padding: false)
  end

  defp sort_primary_varints(varints) do
    varints
    |> Enum.sort(:desc)
    |> Enum.flat_map(fn {_quant, cards} ->
      facs =
        cards
        # 0. group cards by set/fac
        |> Enum.group_by(
          fn {set, fac, _num} -> {set, fac} end,
          fn {_set, _fac, num} -> num end
        )

      # Sort and flatten the card codes
      #
      # How official library sorts:
      # https://github.com/RiotGames/LoRDeckCodes/blob/52d10f702e98ca048fc241622e4c7e306d826919/LoRDeckCodes/LoRDeckEncoder.cs#L223-L234
      # 1. Sort by number of distinct cards of a set/fac group, in ascending order
      # 2. Sort the set/fac groups alphanumerically by the card code, in ascending order
      # 3. Sort the card numbers, in ascending order
      vals =
        facs
        # 1. sort the groups by the number of distinct cards
        |> Enum.group_by(fn {_, nums} -> length(nums) end)
        |> Enum.sort()
        # 2. sort set/fac groups alphanumerically
        |> Enum.flat_map(fn {_len, facs} ->
          Enum.sort_by(facs, fn {{set, fac}, _nums} ->
            {_, _, fac_code} = Faction.fetch_by_id!(fac)
            # NOTE: this _should_ effectively be the same as string
            # comparison since sets are zero padded and tuples should
            # be compared in order
            {set, fac_code}
          end)
        end)
        |> Enum.flat_map(fn {{set, fac}, nums} ->
          # 3. flatten set/fac group in sorted num order
          [length(nums), set, fac | Enum.sort(nums)]
        end)

      [map_size(facs) | vals]
    end)
  end

  defp sort_special_varints(varints) do
    varints
    |> Enum.sort()
    |> Enum.flat_map(fn {quant, cards} ->
      cards
      |> Enum.sort()
      |> Enum.flat_map(fn {set, fac, num} ->
        [quant, set, fac, num]
      end)
    end)
  end

  # `Map.split/2` but if the key doesn't exist, include it mapping to the
  # default value
  @spec map_split_default(map, [Map.key()], term) :: {map, map}
  defp map_split_default(map, keys, default) do
    {a, b} = Map.split(map, keys)
    d = Map.new(keys, &{&1, default})
    d_a = Map.merge(d, a)
    {d_a, b}
  end
end

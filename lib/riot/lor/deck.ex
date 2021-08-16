defmodule Riot.LoR.Deck do
  @moduledoc """
  Type and functions to represent a LoR deck, i.e., cards and their respective
  counts.
  """

  alias Riot.LoR.Card
  alias Riot.LoR.Faction

  @type t :: %{Card.t() => pos_integer}
  @type card_counts :: [{binary, pos_integer}]

  defguardp is_pos_integer(v) when is_integer(v) and v >= 1

  @doc """
  Create an empty `Riot.LoR.Deck`

  ## Examples

      iex> Riot.LoR.Deck.new()
      %{}

  """
  @doc since: "1.0.0"
  @spec new :: t()
  def new, do: %{}

  @doc """
  Populate a new `Riot.LoR.Deck` from a list of cards and their counts.

  ## Examples

      iex> cards = [{"01DE001", 3}, {"01DE002", 2}]
      iex> Riot.LoR.Deck.from_card_counts!(cards)
      %{
        %Riot.LoR.Card{fac: 0, num: 1, set: 1} => 3,
        %Riot.LoR.Card{fac: 0, num: 2, set: 1} => 2
      }

  """
  @doc since: "1.0.0"
  @spec from_card_counts!(card_counts) :: t()
  def from_card_counts!(card_counts) do
    # NOTE: intentionally doesn't use Enum.into/3 to utilize add_card/3
    Enum.reduce(card_counts, new(), fn {card_code, count}, deck ->
      add_card_code!(deck, card_code, count)
    end)
  end

  @doc """
  Add a `Riot.LoR.Card` count to a `Riot.LoR.Deck`. By default it will
  increment the count by 1. You can increment by any positive integer.

  ## Examples

      iex> deck = Riot.LoR.Deck.new()
      iex> deck = Riot.LoR.Deck.add_card(deck, %Riot.LoR.Card{set: 1, fac: 0, num: 1})
      %{%Riot.LoR.Card{fac: 0, num: 1, set: 1} => 1}
      iex> deck = Riot.LoR.Deck.add_card(deck, %Riot.LoR.Card{set: 1, fac: 0, num: 2}, 2)
      %{
        %Riot.LoR.Card{fac: 0, num: 1, set: 1} => 1,
        %Riot.LoR.Card{fac: 0, num: 2, set: 1} => 2
      }
      iex> Riot.LoR.Deck.add_card(deck, %Riot.LoR.Card{set: 1, fac: 0, num: 1}, 2)
      %{
        %Riot.LoR.Card{fac: 0, num: 1, set: 1} => 3,
        %Riot.LoR.Card{fac: 0, num: 2, set: 1} => 2
      }

  """
  @doc since: "1.0.0"
  @spec add_card(t(), Card.t(), pos_integer) :: t()
  def add_card(deck, %Card{} = card, count \\ 1) when is_pos_integer(count) do
    Map.update(deck, card, count, &(&1 + count))
  end

  @doc """
  Add a raw card code to a `Riot.LoR.Deck`. By default it will increment the
  count by 1. You can intrement by any positive integer.

  This is a convenience wrapper around `Riot.LoR.Deck.add_card/3`.

  ## Examples

      iex> deck = Riot.LoR.Deck.new()
      iex> deck = Riot.LoR.Deck.add_card_code!(deck, "01DE001")
      %{%Riot.LoR.Card{fac: 0, num: 1, set: 1} => 1}
      iex> Riot.LoR.Deck.add_card_code!(deck, "01DE001", 2)
      %{%Riot.LoR.Card{fac: 0, num: 1, set: 1} => 3}

  """
  @doc since: "1.0.0"
  @spec add_card_code!(t(), binary, pos_integer) :: t()
  def add_card_code!(deck, card_code, count \\ 1) when is_pos_integer(count) do
    card = Card.parse!(card_code)
    add_card(deck, card, count)
  end

  @doc """
  Remove a `Riot.LoR.Card` from a `Riot.LoR.Deck`. By default it will decrement
  the count by 1. You can can specify any positive integer to decrement the
  count by.

  If you pass `:all` or an integer greater than or equal to the current count
  the `Riot.LoR.Card` will be removed from the `Riot.LoR.Deck`.

  ## Examples

      iex> cards = [{"01DE001", 3}, {"01DE002", 2}, {"01DE003", 1}]
      iex> deck = Riot.LoR.Deck.from_card_counts!(cards)
      %{
        %Riot.LoR.Card{fac: 0, num: 1, set: 1} => 3,
        %Riot.LoR.Card{fac: 0, num: 2, set: 1} => 2,
        %Riot.LoR.Card{fac: 0, num: 3, set: 1} => 1
      }
      iex> deck = Riot.LoR.Deck.remove_card(deck, %Riot.LoR.Card{set: 1, fac: 0, num: 3})
      %{
        %Riot.LoR.Card{fac: 0, num: 1, set: 1} => 3,
        %Riot.LoR.Card{fac: 0, num: 2, set: 1} => 2
      }
      iex> deck = Riot.LoR.Deck.remove_card(deck, %Riot.LoR.Card{set: 1, fac: 0, num: 2}, 2)
      %{%Riot.LoR.Card{fac: 0, num: 1, set: 1} => 3}
      iex> deck = Riot.LoR.Deck.remove_card(deck, %Riot.LoR.Card{set: 1, fac: 0, num: 1})
      %{%Riot.LoR.Card{fac: 0, num: 1, set: 1} => 2}
      iex> Riot.LoR.Deck.remove_card(deck, %Riot.LoR.Card{set: 1, fac: 0, num: 1}, :all)
      %{}

  """
  @doc since: "1.0.0"
  @spec remove_card(t(), Card.t(), pos_integer | :all) :: t()
  def remove_card(deck, card, count \\ 1)

  def remove_card(deck, %Card{} = card, :all) do
    {_, deck} = Map.pop(deck, card)
    deck
  end

  def remove_card(deck, %Card{} = card, count) when is_pos_integer(count) do
    {_, deck} =
      Map.get_and_update(deck, card, fn
        nil -> :pop
        quantity when quantity <= count -> :pop
        quantity -> {quantity, quantity - count}
      end)

    deck
  end

  @doc """
  Returns the minimum version required to support the cards in deck.
  If no minimum is found (e.g., the deck is empty), return the smallest version
  supported by the library.

  ## Examples

      iex> cards = [{"03MT054", 1}, {"05BC198", 1}]
      iex> deck = Riot.LoR.Deck.from_card_counts!(cards)
      iex> Riot.LoR.Deck.min_required_version(deck)
      4

  """
  @doc since: "1.0.0"
  @spec min_required_version(t()) :: pos_integer
  def min_required_version(deck) when is_map(deck) do
    deck
    |> Map.keys()
    |> Enum.map(fn %Card{fac: f} ->
      {ver, _id, _code} = Faction.fetch_by_id!(f)
      ver
    end)
    |> Enum.max(&Faction.min_version/0)
  end

  @doc """
  Return a list of card codes and their counts.

  ## Examples

      iex> deck = Riot.LoR.Deck.new()
      %{}
      iex> deck = Riot.LoR.Deck.add_card(deck, %Riot.LoR.Card{set: 1, fac: 0, num: 1}, 3)
      %{%Riot.LoR.Card{fac: 0, num: 1, set: 1} => 3}
      iex> Riot.LoR.Deck.code_count(deck)
      [{"01DE001", 3}]

  """
  @doc since: "1.0.0"
  @spec code_count(t()) :: card_counts()
  def code_count(deck) when is_map(deck) do
    deck
    |> Enum.map(fn {card, count} ->
      {Card.to_code!(card), count}
    end)
    |> Enum.sort()
  end
end

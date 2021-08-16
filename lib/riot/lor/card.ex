defmodule Riot.LoR.Card do
  @moduledoc """
  Struct and functions to represent LoR Cards.
  """

  alias __MODULE__
  alias Riot.LoR.Faction

  import Riot.LoR.Faction, only: [is_id: 1]

  @enforce_keys [:set, :fac, :num]
  defstruct [:set, :fac, :num]

  @type t :: %Card{
          set: non_neg_integer,
          fac: non_neg_integer,
          num: non_neg_integer
        }

  @doc false
  defguard is_card_num(n) when is_integer(n) and n in 1..999
  @doc false
  defguard is_card_set(s) when is_integer(s) and s in 1..99

  @doc """
  Create a `Card` from a tuple of it's set, faction id, and number.

  ## Examples

      iex> Riot.LoR.Card.new({1, 0, 1})
      %Riot.LoR.Card{fac: 0, num: 1, set: 1}

  """
  @doc since: "1.0.0"
  @spec new({non_neg_integer, non_neg_integer, non_neg_integer}) :: t()
  def new({set, fac, num}) when is_card_set(set) and is_id(fac) and is_card_num(num) do
    %Card{set: set, fac: fac, num: num}
  end

  @doc """
  Create a `Card` from a card code string.

  ## Examples

      iex> Riot.LoR.Card.parse!("01DE001")
      %Riot.LoR.Card{fac: 0, num: 1, set: 1}

  """
  @doc since: "1.0.0"
  @spec parse!(binary) :: t()
  def parse!(<<set_str::binary-size(2), fac_code::binary-size(2), num_str::binary-size(3)>>) do
    set = String.to_integer(set_str)
    {_ver, fac_id, ^fac_code} = Faction.fetch_by_code!(fac_code)
    num = String.to_integer(num_str)

    new({set, fac_id, num})
  end

  @doc """
  Represent a `Card` as a tuple of its set, faction id, and number.

  ## Examples

      iex> card = %Riot.LoR.Card{set: 1, fac: 0, num: 1}
      %Riot.LoR.Card{fac: 0, num: 1, set: 1}
      iex> Riot.LoR.Card.as_tuple(card)
      {1, 0, 1}

  """
  @doc since: "1.0.0"
  @spec as_tuple(t()) :: {non_neg_integer, non_neg_integer, non_neg_integer}
  def as_tuple(%Card{set: s, fac: f, num: n}), do: {s, f, n}

  @doc """
  Represent a `Card` as its card code string.

  ## Examples

      iex> card = %Riot.LoR.Card{set: 1, fac: 0, num: 1}
      %Riot.LoR.Card{fac: 0, num: 1, set: 1}
      iex> Riot.LoR.Card.to_code!(card)
      "01DE001"

  """
  @doc since: "1.0.0"
  @spec to_code!(t()) :: binary
  def to_code!(%Card{} = card) do
    {set, fac_id, num} = as_tuple(card)

    set_str = set |> to_string() |> String.pad_leading(2, "0")
    {_ver, ^fac_id, fac_code} = Faction.fetch_by_id!(fac_id)
    num_str = num |> to_string() |> String.pad_leading(3, "0")

    set_str <> fac_code <> num_str
  end
end

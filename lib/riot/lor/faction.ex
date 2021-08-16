defmodule Riot.LoR.Faction do
  @moduledoc """
  Static support for supported LoR Factions.

  Supported Factions are hard-coded into to the module. Through the
  functions you can fetch information by id, code, etc.
  """

  @type t :: {version :: non_neg_integer, id :: non_neg_integer, code :: binary}

  @factions [
    {1, 0, "DE"},
    {1, 1, "FR"},
    {1, 2, "IO"},
    {1, 3, "NX"},
    {1, 4, "PZ"},
    {1, 5, "SI"},
    # Version 2
    {2, 6, "BW"},
    {2, 9, "MT"},
    # Version 3
    {3, 7, "SH"},
    # Version 4
    {4, 10, "BC"}
  ]

  # NOTE: assumes versions are contiguous
  @versions @factions
            |> Enum.map(fn {v, _i, _c} -> v end)
            |> Enum.min_max()
            |> (fn {f, l} -> Range.new(f, l) end).()

  # NOTE: does _not_ assume ids are contiguous, but are unique
  @ids @factions |> Enum.map(fn {_v, i, _c} -> i end) |> Enum.sort()

  # NOTE: assumes codes are unique. Ids should map to codes 1:1
  @codes @factions |> Enum.map(fn {_v, _i, c} -> c end) |> Enum.sort()

  @factions_by_id Map.new(@factions, fn {_v, i, _c} = f -> {i, f} end)
  @factions_by_code Map.new(@factions, fn {_v, _i, c} = f -> {c, f} end)

  @doc false
  defguard is_code(v) when is_binary(v) and v in @codes
  @doc false
  defguard is_id(v) when is_integer(v) and v in @ids
  @doc false
  defguard is_version(v) when is_integer(v) and v in @versions

  @doc """
  Get a Faction code from its id.

  ## Examples

      iex> Riot.LoR.Faction.fetch_by_id!(0)
      {1, 0, "DE"}

  """
  @doc since: "1.0.0"
  @spec fetch_by_id!(integer) :: t()
  def fetch_by_id!(id) when is_id(id), do: Map.fetch!(@factions_by_id, id)

  @doc """
  Get a Faction id from its code.

  ## Examples

      iex> Riot.LoR.Faction.fetch_by_code!("DE")
      {1, 0, "DE"}

  """
  @doc since: "1.0.0"
  @spec fetch_by_code!(binary) :: t()
  def fetch_by_code!(code) when is_code(code), do: Map.fetch!(@factions_by_code, code)

  @doc """
  Get the minimum version supported.

  ## Examples

      iex> Riot.LoR.Faction.min_version()
      1

  """
  @doc since: "1.0.0"
  @spec min_version() :: non_neg_integer()
  def min_version, do: @versions.first

  @doc """
  Get the maximum version supported.

  ## Examples

      iex> Riot.LoR.Faction.max_version()
      4

  """
  @doc since: "1.0.0"
  @spec max_version() :: non_neg_integer()
  def max_version, do: @versions.last
end

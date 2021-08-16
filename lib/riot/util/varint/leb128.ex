defmodule Riot.Util.Varint.LEB128 do
  @moduledoc """
  More on LEB128:
  * https://en.wikipedia.org/wiki/LEB128
  * https://wiki.vg/Protocol#VarInt_and_VarLong
  * https://developers.google.com/protocol-buffers/docs/encoding#varints

  Other LEB128 implementations:
  * protobuf (Python):
    * decode: https://github.com/protocolbuffers/protobuf/blob/75eff10d81233d3d08ce5ded215e526c1fcace88/python/google/protobuf/internal/decoder.py#L107-L120
    * encode: https://github.com/protocolbuffers/protobuf/blob/75eff10d81233d3d08ce5ded215e526c1fcace88/python/google/protobuf/internal/encoder.py#L375-L382
  * Golang:
    * decode: https://pkg.go.dev/encoding/binary#Uvarint
    * encode: https://pkg.go.dev/encoding/binary#PutUvarint
  """
  @moduledoc since: "1.0.0"

  alias Riot.Util.Varint

  use Bitwise, only_operators: true

  import Riot.Util.Varint, only: [has_octet: 1, is_pos_integer: 1]

  ##########
  # Decode #
  ##########

  ## All ##

  @doc """
  Decodes all varint sequences

  ## Examples

      iex> Riot.Util.Varint.LEB128.decode_all(<<8, 172, 2, 151, 195, 6>>)
      {[8, 300, 106903], "", 6}

  """
  @doc since: "1.0.0"
  @spec decode_all(bitstring, :unsigned | :signed) :: {[integer], bitstring, integer}
  def decode_all(subject, sign \\ :unsigned) when is_bitstring(subject) do
    do_decode_all(subject, sign, [], 0)
  end

  @spec do_decode_all(bitstring, :unsigned | :signed, [integer], integer) ::
          {[integer], bitstring, integer}
  defp do_decode_all(subject, sign, ints, total_bytes) when has_octet(subject) do
    {int, rest, num_bytes} = decode_next(subject, sign)
    do_decode_all(rest, sign, [int | ints], num_bytes + total_bytes)
  end

  defp do_decode_all(leftover, _sign, ints, total_bytes) do
    {Enum.reverse(ints), leftover, total_bytes}
  end

  ## Next ##

  @doc """
  Decodes the next varint sequence

  ## Examples

      iex> {_, rest, _} = Riot.Util.Varint.LEB128.decode_next(<<8, 172, 2>>)
      {8, <<172, 2>>, 1}
      iex> Riot.Util.Varint.LEB128.decode_next(rest)
      {300, "", 2}

  """
  @doc since: "1.0.0"
  @spec decode_next(bitstring, :unsigned | :signed) :: {integer, bitstring, integer}
  def decode_next(subject, sign \\ :unsigned)

  def decode_next(subject, :unsigned) when has_octet(subject) do
    do_decode_next_unsigned(subject, 0, 0)
  end

  defp do_decode_next_unsigned(<<octet::integer-size(8), rest::bitstring>>, val, num_bytes) do
    val = val ||| (octet &&& 0x7F) <<< (7 * num_bytes)
    num_bytes = num_bytes + 1

    if (octet &&& 0x80) == 0 do
      {val, rest, num_bytes}
    else
      do_decode_next_unsigned(rest, val, num_bytes)
    end
  end

  defp do_decode_next_unsigned(_leftover, _incomplete_val, num_bytes),
    do: raise(Varint.UnterminatedOctetSequence, num_bytes)

  ##########
  # Encode #
  ##########

  @doc """
  Encode an integer to a varint sequence

  ## Examples

      iex> Riot.Util.Varint.LEB128.encode(999)
      <<231, 7>>

  """
  @doc since: "1.0.0"
  @spec encode(integer, :unsigned | :signed) :: bitstring
  def encode(int, sign \\ :unsigned)

  # NOTE: assume no distinction between 0 and -0
  #       this may not be entirely correct
  def encode(0, _sign), do: <<0>>

  def encode(int, :unsigned) when is_pos_integer(int) do
    do_encode_unsigned(int, <<>>)
  end

  @spec do_encode_unsigned(non_neg_integer, bitstring) :: bitstring
  defp do_encode_unsigned(0, sequence), do: sequence

  # NOTE: don't believe we need to bound size with large int
  # https://erlang.org/doc/efficiency_guide/advanced.html#memory
  defp do_encode_unsigned(val, sequence) do
    octet = val &&& 0x7F
    val = val >>> 7
    octet = if val != 0, do: octet ||| 0x80, else: octet
    do_encode_unsigned(val, sequence <> <<octet>>)
  end
end

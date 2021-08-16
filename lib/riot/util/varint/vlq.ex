defmodule Riot.Util.Varint.VLQ do
  @moduledoc """
  More on VLQs
  * https://en.wikipedia.org/wiki/Variable-length_quantity
  """

  alias Riot.Util.Varint

  use Bitwise, only_operators: true

  import Riot.Util.Varint, only: [has_octet: 1, is_pos_integer: 1]

  ##########
  # Decode #
  ##########

  ## All ##

  @doc """
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
  """
  @doc since: "1.0.0"
  @spec decode_next(bitstring, :unsigned | :signed) :: {integer, bitstring, integer}
  def decode_next(subject, sign \\ :unsigned)

  # NOTE: will fail when there is no ending octet, e.g.
  # <<0b10011111, 0b10001111>>
  # should error out when there's no octet with a 0 MSB in sequence
  def decode_next(subject, :unsigned) when has_octet(subject) do
    do_decode_next_unsigned(subject, 0, 0)
  end

  defp do_decode_next_unsigned(<<octet::integer-size(8), rest::bitstring>>, val, num_bytes) do
    val = val <<< 7 ||| (octet &&& 0x7F)
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

  # Don't make MSB 1 for the first octet
  defp do_encode_unsigned(val, <<>>) do
    octet = val &&& 0x7F
    do_encode_unsigned(val >>> 7, <<octet>>)
  end

  # Make MSB 1 for the remaining octets
  defp do_encode_unsigned(val, sequence) do
    octet = (val &&& 0x7F) ||| 0x80
    do_encode_unsigned(val >>> 7, <<octet>> <> sequence)
  end
end

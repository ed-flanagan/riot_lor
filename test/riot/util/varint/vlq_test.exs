defmodule Riot.Util.Varint.VLQTest do
  alias Riot.Util.Varint
  alias Riot.Util.Varint.VLQ

  use Bitwise, only_operators: true
  use ExUnit.Case
  use ExUnitProperties

  doctest VLQ

  describe "VLQ.decode_all/1" do
    test "unsigned valid" do
      [
        {<<134, 193, 23>>, {[106_647], <<>>, 3}},
        {<<134, 193, 23, 134, 195, 23>>, {[106_647, 106_903], <<>>, 6}},
        {<<134, 193, 23, 1::1>>, {[106_647], <<1::size(1)>>, 3}},
        {<<134, 193, 23, 134, 195, 23, 1::1>>, {[106_647, 106_903], <<1::size(1)>>, 6}}
      ]
      |> Enum.each(fn {input, expected} ->
        assert VLQ.decode_all(input) == expected
      end)
    end

    test "unsigned invalid" do
      # Non-terminating sequence (i.e. no octet with a 0 MSB)
      [
        {<<134>>, 1},
        {<<134, 193, 192>>, 3},
        # TODO: do we want `decode_all` to return total bytes, i.e. 6?
        {<<134, 193, 23, 134, 195, 192>>, 3}
      ]
      |> Enum.each(fn {input, expected_bytes_read} ->
        assert_raise Varint.UnterminatedOctetSequence,
                     "unterminated octet sequence after reading #{expected_bytes_read} bytes",
                     fn -> VLQ.decode_all(input) end
      end)
    end
  end

  describe "VLQ.decode_next/1" do
    test "unsigned valid" do
      [
        {<<134, 193, 23>>, {106_647, <<>>, 3}},
        {<<134, 193, 23, 134, 195, 23>>, {106_647, <<134, 195, 23>>, 3}},
        {<<134, 193, 23, 1::1>>, {106_647, <<1::size(1)>>, 3}},
        {<<134, 193, 23, 134, 195, 23, 1::1>>, {106_647, <<134, 195, 23, 1::size(1)>>, 3}}
      ]
      |> Enum.each(fn {input, expected} ->
        assert VLQ.decode_next(input) == expected
      end)
    end

    test "unsigned invalid" do
      [
        {<<134>>, 1},
        {<<134, 193, 192>>, 3},
        {<<134, 193, 192, 134, 195, 192>>, 6}
      ]
      |> Enum.each(fn {input, expected_bytes_read} ->
        assert_raise Varint.UnterminatedOctetSequence,
                     "unterminated octet sequence after reading #{expected_bytes_read} bytes",
                     fn -> VLQ.decode_next(input) end
      end)
    end
  end

  describe "VLQ.encode/1" do
    test "unsigned valid" do
      [
        {0, <<0>>},
        {5, <<5>>},
        {127, <<127>>},
        {128, <<129, 0>>},
        {999, <<135, 103>>},
        {106_903, <<134, 195, 23>>},
        # Value out of bounds of small int
        {600_000_000_000_000_000, <<136, 169, 232, 154, 163, 137, 240, 128, 0>>}
      ]
      |> Enum.each(fn {input, expected} ->
        assert VLQ.encode(input) == expected
      end)
    end

    # Useful seeds:
    # * 49502: includes the end of range values, i.e. `max`
    property "expected octet size" do
      # NOTE: LoR card numbers are spec'ed to have a maximum of 999, which is
      #       represented with 2 octets
      max_octets = 3
      # NOTE: purposefully unfold octet ranges to ensure each range is covered
      #       equally, up to the `max_octets`
      Stream.unfold({0, 127}, fn {min, max} ->
        # alt: {{min, max}, {max + 1, ((max + 1) <<< 7) - 1}}
        {{min, max}, {max + 1, max <<< 7 ||| 0x7F}}
      end)
      # Expected ranges:
      # [{0, 127}, {128, 16383}, {16384, 2097151}]
      |> Enum.take(max_octets)
      |> Enum.with_index(1)
      |> Enum.each(fn {{min, max}, num_octets} ->
        check all int <- integer(min..max) do
          result = VLQ.encode(int)
          assert bit_size(result) == 8 * num_octets
        end
      end)
    end
  end

  property "unsigned encoding + decoding is circular" do
    check all int <- map(integer(), &abs/1) do
      {result, _, _} =
        int
        |> VLQ.encode()
        |> VLQ.decode_next()

      assert int == result
    end
  end
end

defmodule Riot.Util.Varint.LEB128Test do
  alias Riot.Util.Varint
  alias Riot.Util.Varint.LEB128

  use Bitwise, only_operators: true
  use ExUnit.Case
  use ExUnitProperties

  doctest LEB128

  describe "LEB128.decode_all/1" do
    test "unsigned valid" do
      [
        {<<127, 127>>, {[127, 127], <<>>, 2}},
        {<<151, 195, 6, 151, 195, 6, 1::1>>, {[106_903, 106_903], <<1::size(1)>>, 6}}
      ]
      |> Enum.each(fn {input, expected} ->
        assert LEB128.decode_all(input) == expected
      end)
    end
  end

  describe "LEB128.decode_next/1" do
    test "unsigned valid" do
      [
        {<<0>>, {0, <<>>, 1}},
        {<<127>>, {127, <<>>, 1}},
        {<<128, 1>>, {128, <<>>, 2}},
        {<<151, 195, 6>>, {106_903, <<>>, 3}},
        {<<127, 127>>, {127, <<127>>, 1}},
        {<<151, 195, 6, 1::1>>, {106_903, <<1::size(1)>>, 3}}
      ]
      |> Enum.each(fn {input, expected} ->
        assert LEB128.decode_next(input) == expected
      end)
    end

    test "unsigned invalid" do
      [
        {<<128>>, 1},
        {<<151, 195, 134>>, 3}
      ]
      |> Enum.each(fn {input, expected_bytes_read} ->
        assert_raise Varint.UnterminatedOctetSequence,
                     "unterminated octet sequence after reading #{expected_bytes_read} bytes",
                     fn -> LEB128.decode_next(input) end
      end)
    end
  end

  describe "LEB128.encode/1" do
    test "unsigned valid" do
      [
        {0, <<0>>},
        {5, <<5>>},
        {127, <<127>>},
        {128, <<128, 1>>},
        {156, <<156, 1>>},
        {300, <<172, 2>>},
        {999, <<231, 7>>},
        {106_903, <<151, 195, 6>>},
        {624_485, <<229, 142, 38>>},
        # Value out of bounds by small integer
        {600_000_000_000_000_000, <<128, 128, 240, 137, 163, 154, 232, 169, 8>>}
      ]
      |> Enum.each(fn {input, expected} ->
        assert LEB128.encode(input) == expected
      end)
    end
  end

  property "unsigned encoding + decoding is circular" do
    check all int <- map(integer(), &abs/1) do
      {result, _, _} =
        int
        |> LEB128.encode()
        |> LEB128.decode_next()

      assert int == result
    end
  end
end

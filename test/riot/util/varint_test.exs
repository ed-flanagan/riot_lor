defmodule Riot.Util.VarintTest do
  alias Riot.Util.Varint

  use ExUnit.Case

  doctest Varint

  describe "guards" do
    test "has_octet" do
      [
        {<<>>, false},
        {<<1::1>>, false},
        {<<1::8>>, true},
        {<<1::8, 1::1>>, true},
        {<<1::8, 1::8>>, true},
        {<<1::8, 1::8, 1::1>>, true}
      ]
      |> Enum.each(fn {input, expected} ->
        assert Varint.has_octet(input) == expected
      end)
    end

    test "is_neg_integer" do
      [
        {-1, true},
        {0, false},
        {1, false}
      ]
      |> Enum.each(fn {input, expected} ->
        assert Varint.is_neg_integer(input) == expected
      end)
    end

    test "is_non_neg_integer" do
      [
        {-1, false},
        {0, true},
        {1, true}
      ]
      |> Enum.each(fn {input, expected} ->
        assert Varint.is_non_neg_integer(input) == expected
      end)
    end

    test "is_pos_integer" do
      [
        {-1, false},
        {0, false},
        {1, true}
      ]
      |> Enum.each(fn {input, expected} ->
        assert Varint.is_pos_integer(input) == expected
      end)
    end
  end
end

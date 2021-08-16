defmodule Riot.Util.Varint do
  @moduledoc false

  defguard has_octet(v) when is_bitstring(v) and bit_size(v) >= 8

  defguard is_neg_integer(v) when is_integer(v) and v < 0
  defguard is_non_neg_integer(v) when is_integer(v) and v >= 0
  defguard is_pos_integer(v) when is_integer(v) and v > 0

  defmodule UnterminatedOctetSequence do
    defexception [:message]

    def exception(num_bytes) do
      msg = "unterminated octet sequence after reading #{num_bytes} bytes"
      %UnterminatedOctetSequence{message: msg}
    end
  end
end

{:ok, deck_codes_file} = File.open("deck_codes.txt", [:read, :utf8])

deck_codes_file
|> IO.stream(:line)
|> Stream.map(&String.trim/1)
|> Stream.chunk_while(
  {},
  fn
    "", {code, card_counts} -> {:cont, {code, Enum.reverse(card_counts)}, {}}
    line, {} -> {:cont, {line, []}}
    line, {code, card_counts} -> {:cont, {code, [line | card_counts]}}
  end,
  fn {code, card_counts} -> {:cont, {code, Enum.reverse(card_counts)}, {}} end
)
|> Enum.to_list()
|> IO.inspect()

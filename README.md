# 🃏 Riot LoR deck code library ⚗️

[![Docs](https://img.shields.io/badge/hex-docs-7851a9?logo=elixir)](https://hexdocs.pm/riot_lor)
[![Build](https://github.com/ed-flanagan/riot_lor/actions/workflows/ci.yaml/badge.svg)](https://github.com/ed-flanagan/riot_lor/actions/workflows/ci.yaml)
[![Coverage Status](https://coveralls.io/repos/github/ed-flanagan/riot_lor/badge.svg?branch=main)](https://coveralls.io/github/ed-flanagan/riot_lor?branch=main)

[Yet another](https://github.com/petter-kaspersen/lor-deck-codes-elixir)
[Elixir](https://elixir-lang.org/)
implementation of
[Riot](https://www.riotgames.com/en)'s
[Legends of Runterra](https://playruneterra.com/en-us/)
[deck code library](https://github.com/RiotGames/LoRDeckCodes).

## Installation

If [using Hex](https://hex.pm/docs/usage), the package can be installed
by adding `:riot_lor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:riot_lor, "~> 1.1.0"}
  ]
end
```

## Usage

### Documentation

Docs can be found at
[https://hexdocs.pm/riot_lor](https://hexdocs.pm/riot_lor).

You can also read supplemental docs under the `docs/` directory.

### Examples

You can run the project locally with `iex -S mix`.
You may want to
[configure IEx](https://hexdocs.pm/elixir/1.12/Inspect.Opts.html) to
* display lists of ints as lists, rather than charlists
* limit inspect enum length to 4, in case your want to limit large outputs of decks

#### Inspect options

```sh
iex \
	--eval 'IEx.configure(inspect: [limit: 4, charlists: :as_lists])' \
	-S mix
```

```elixir
iex(1)> IEx.configure(inspect: [limit: 4, charlists: :as_lists])
:ok
```

#### Decoding

```elixir
iex(2)> deck_code = "CEAAECABAQJRWHBIFU2DOOYIAEBAMCIMCINCILJZAICACBANE4VCYBABAILR2HRL"
"CEAAECABAQJRWHBIFU2DOOYIAEBAMCIMCINCILJZAICACBANE4VCYBABAILR2HRL"
iex(3)> deck = Riot.LoR.DeckCode.decode!(deck_code)
%{
  %Riot.LoR.Card{fac: 2, num: 6, set: 1} => 2,
  %Riot.LoR.Card{fac: 2, num: 9, ...} => 2,
  %Riot.LoR.Card{fac: 2, ...} => 2,
  %Riot.LoR.Card{...} => 2,
  ...
}
iex(4)> Riot.LoR.Deck.code_count(deck)
[{"01IO006", 2}, {"01IO009", 2}, {"01IO012", ...}, {...}, ...]
```

#### Encoding

```elixir
iex(5)> card_counts = [{"01DE001", 1}, {"05BC198", 1}]
[{"01DE001", 1}, {"05BC198", 1}]
iex(6)> deck = Riot.LoR.Deck.from_card_counts!(card_counts)
%{
  %Riot.LoR.Card{fac: 0, num: 1, set: 1} => 1,
  %Riot.LoR.Card{fac: 10, num: 198, set: 5} => 1
}
iex(7)> Riot.LoR.DeckCode.encode!(deck)
"CQAAAAQBAEAACAIFBLDAC"
```

## Contributing

See the `CONTRIBUTING.md` file.

## Legal

Licensed under the MIT License. See the LICENSE file for more details.

Per [Riot's Core Policies](https://developer.riotgames.com/policies/general#_core-policies):

The `riot_lor` project isn't endorsed by Riot Games and doesn't reflect the
views or opinions of Riot Games or anyone officially involved in producing or
managing Riot Games properties. Riot Games, and all associated properties are
trademarks or registered trademarks of Riot Games, Inc.


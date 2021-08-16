# LoR deck codes

A LoR deck code is a [Base32](https://en.wikipedia.org/wiki/Base32) encoded
binary sequence representing:
1. The deck code format
2. The minimum version required for the cards in deck
3. A set of LoR card codes and their respective quantity

The [official library](https://github.com/RiotGames/LoRDeckCodes) states[^1]

> Decks are encoding via arranging VarInts (big endian) into an array and then
> base 32 encoding into a string.
> All encodings begin with 4 bits for format and 4 bits for version.


You may interpret this as meaning the entirety of the byte sequence is composed
of VarInts octets, _including_ each prefix value (bundled as a single VarInt
octet, which would only leave 3 bits for format).

However, in the current implementation, decks are encoded by:
1. Creating an empty list of bytes[^2]
2. Adding one byte where high 4 bits are format and low 4 bits are version[^3]
3. Adding sequences of VarInts for the cards[^4]
4. Base32 encode the byte list[^5]


Further, for decoding, the first 8 bits are extracted _before_ reading VarInts[^6].

Furthermore, the VarInts the official library use are actually LEB128, i.e.
little-engine, _not_ big-endian[^7].

The VarInt sequence is a serialization of a hierarchical representation of card
codes and their quantities. More on this in sections below.

## Concepts

### Format

The format is presumably the "version" for the deck code format itself, i.e.
what values/ordering to expect.

Currently, the only version is `1`. We can see that format is currently unused
while decoding[^8]. Further, is a hard-coded[^9] value while encoding[^10].

We can assume this value may increment if the values/order of anything for
future game updates.

The maximum format value is 15, since it is represented by 4 bits. This maximum
is likely fixed forever since all deck codes will likely need to start by
reading the format before continuing to scan.

### Version

Riot marks versions for LoR. [AFAICT](https://en.wiktionary.org/wiki/AFAICT),
they largely signify the release of a new faction.

You can see major patch releases
[here](https://github.com/RiotGames/LoRDeckCodes#process) and faction/version
mappings [here](https://github.com/RiotGames/LoRDeckCodes#faction-identifiers)

Version changes are up to Riot's discretion internally. There has been some
elaboration through issues[^11].

### Card codes

> Every Legends of Runeterra card has a corresponding card code. Card codes are
> seven character strings comprised of two characters for card set, two
> characters for faction identifier, and three characters for card number.

-- https://github.com/RiotGames/LoRDeckCodes#cards--decks

A card code is a 7 character string comprised of 3 components
1. Card set - a 2 character, zero-padded integer
2. Faction slug - a 2 character string
3. Card number - a 3 character, zero-padded integer

Breaking down the example `"01DE123"`
([which is not a real card](https://lor.mobalytics.gg/cards/01DE123)).
```
01 DE 055
│  │  │
│  │  │
│  │  └─ "055" is the card number. Unique to the combination of set+faction
│  │
│  └─ "DE" is the faction slug. Each slug has a corresponding numerical ID
│
└─ "01" is the card set
```

#### Sets

AFAICT, sets are releases of bundles of cards, across factions. Riot's developer
portal provides
[assets divvied by set](https://developer.riotgames.com/docs/lor#data-dragon_set-bundles).

Sets are distinct from version.

#### Factions

Every card belongs to one or more factions. Card codes utilize a 2 character
slug. However, each slug has a corresponding integer id, which is used in the
deck code encoding (described below).

#### Card number

Card numbers are unique to each combination of set and faction. They start at 1
and increment for each card in the set/faction combo.

For example `01DE001` and `02DE001` are two distinct cards sharing the same
card number.

## Unpacking deck codes

### Base32

Deck code values are encoded in [Base32](https://en.wikipedia.org/wiki/Base32).

AFAICT, the official library:
* Uses [RFC 4648](https://datatracker.ietf.org/doc/html/rfc4648#section-6)
  alphabet[^12], i.e. `/[A-Z2-7]/`
* Doesn't pad by default[^13][^14], but can with `=`

### Format prefix

The first 4 bits are the format value. Currently there is only one: `1`.

Presumably the value will increment if changed in the future. Further, data
following the format may depend on the format. I.e. following sections may
depend on the given format.

Since there's only one legal format version, we'll assume that for the
following sections.

### Version prefix

The next 4 bits are the version value. It represents the minimum game version
required for the following.

If/when the version is about to surpass 15, it may require a new format version.

### Card VarInt sequence

Following the fixed prefix, is a sequence of
[unsigned LEB128 VarInts](https://en.wikipedia.org/wiki/LEB128#Unsigned_LEB128)
of arbitrary size.

While the card VarInts are a list, the serialization represents a hierarchy.
I imagine this an attempt represent each card in a more dense manner, i.e.
shortening the total deck code as short as possible.

There are 3 general levels (groupings) in the hierarchy:
1. The card quantity (e.g., 1, 2, & 3. 4+ is a special case)
2. A combination of card set & card faction
3. The card number

Any quantities >=4 are not apart of the hierarchy. Instead, it's a list of
quantity + card code values (e.g. `[ {quant, [set, fac, num]}, ... ]`).

Here's a mapping to try and help to visualize. The first key is the
quantity of cards within the value. The second key is a combination of the
set & faction. The list value are the cards numbers.

```
# General map
{
  1: {
    {1, 2}: [10, 12],
    {1, 4}: [10, 21],
    {2, 4}: [10]
  },
  2: {},
  3: {
    {1, 4}: [27]
  },
  4+: [
    {4, [1, 2, 30]},
    {5, [2, 4, 30]}
  ]
}

# This mapping expands (ignoring 4+) out to individual card codes like this
["01IO010", "01IO012", "01PZ010", "01PZ21", "02PZ010", "01PZ027", "01PZ027", "01PZ027"]
  │            │                  ├─────────────────┘  ├─────────────────────────────┘
  │            │                  │ distinct combi of  │
  │            │                  └ set+faction        └ Cards repeated within quanity group
  │            │
  │            └ The faction id converted to the slug
  │
  └ A card code (described above)
```

So how does the VarInt sequence actually represent this hierarchy? There are no
special delimiters to signify the start/end of any value/group. Instead, the
sequence follows a pattern. By following this pattern you can extract two
general classes of values:
1. Count of entity
2. Literal value

Literal values are grouped together. You can know how many of these values are
in the group by the preceding value, representing the count. Lets take a look
and break down the example deck code from the official library

```
Deck code example from the official library page:
CEAAECABAQJRWHBIFU2DOOYIAEBAMCIMCINCILJZAICACBANE4VCYBABAILR2HRL

Base32 decode gives us this sequence of bytes (represented as integers):
<<17, 0, 2, 8, 1, 4, 19, 27, 28, 40, 45, 52, 55, 59, 8, 1, 2, 6, 9, 12, 18, 26, 36, 45, 57, 2, 4, 1, 4, 13, 39, 42, 44, 4, 1, 2, 23, 29, 30, 43>>

The first byte is 17 or 0b0001 0001. The high 4 bits is the format and the low
4 bits is the version. Both are 1.

After popping the first byte, continuing with format 1, we have the varint
sequence representing the deck's cards.

If we decode the varint sequence, we'll have this list of integers:
[0, 2, 8, 1, 4, 19, 27, 28, 40, 45, 52, 55, 59, 8, 1, 2, 6, 9, 12, 18, 26, 36, 45, 57, 2, 4, 1, 4, 13, 39, 42, 44, 4, 1, 2, 23, 29, 30, 43]

Note that the encoded/decoded sequence hold the same values. This is because
all varint octets were less than 128, i.e. the length of all Varints was 1.
An example of a LEB128 varint with a length > 1 is <<172, 2>>, which represents the integer value 300
So the sequence <<8, 172, 2, 6>> would decode to [8, 300, 6]

Lets break down each integer value
[0, 2, 8, 1, 4, 19, 27, 28, 40, 45, 52, 55, 59, 8, 1, 2, 6, 9, 12, 18, 26, 36, 45, 57, 2, 4, 1, 4, 13, 39, 42, 44, 4, 1, 2, 23, 29, 30, 43]
 │  │  │  │  │  ├────────────────────────────┘  │  │  │  ├──────────────────────────┘  │  │  │  │  ├────────────┘  │  │  │  ├────────────┘
 │  │  │  │  │  │                               │  │  │  │                             │  │  │  │  │               │  │  │  │
 │  │  │  │  │  └ the 8 card numbers            │  │  │  └ the 8 card numbers          │  │  │  │  └ the 4 card #s │  │  │  └ the 4 card nums
 │  │  │  │  │                                  │  │  │                                │  │  │  │                  │  │  │
 │  │  │  │  └ the faction id                   │  │  └ the faction id                 │  │  │  └ the faction id   │  │  └ faction id
 │  │  │  │                                     │  │                                   │  │  │                     │  │
 │  │  │  └ the set id                          │  └ the set id                        │  │  └ the set id          │  └ set id
 │  │  │                                        │                                      │  │                        │
 │  │  └ there are 8 cards in the first (1/2)   └ there are 8 cards in the first (1/2) │  └ there are 4 cards in   └ there are 4 cards in
 │  │    set/faction group                      set/faction group                      │    the first (1/2)          the second (2/2)
 │  │                                                                                  │    set/faction group        set/faction group
 │  └ num of set/faction groups with quantity 2                                        │
 │                                                                                     └ num of set/faction groups with quantity 1
 └ num of set/faction groups with quantity 3

```

Another way to visualize is by making a tree. The first value is the index the
value would appear in. You can generally read top-to-bottom, like a list, but
notice how each "count" type value branches out to a list of "literal" values.

```

As a heirarchy (<index>_<kind>_<value>)
├── 01_format_1
├── 02_version_1
├── 03_quant3_2
│   ├── 04_combi_2
│   │   ├── 05_set_1
│   │   ├── 06_faction_2
│   │   ├── 07_card_001
│   │   └── 08_card_002
│   └── 09_combi_1
│       ├── 10_set_2
│       ├── 11_faction_9
│       └── 12_card_010
├── 13_quant2_0
├── 14_quant1_1
│   └── 15_combi_2
│       ├── 16_set_1
│       ├── 17_faction_2
│       ├── 18_card_007
│       └── 19_card_005
├── 20_countN_4
├── 21_set_1
├── 22_faction_2
└── 23_card_020
```

We can see there are 2 "count" types
1. Number of set/faction groups, within a given quantity group
2. Number of cards, within a given set/faction group

We create the set/faction combination by read the first two integers after
the card count. After those two, ready the card numbers.

Some pseduocode to represent the generic process if the quantity values were
arbitrary

```
deck_values = [...]
quantity_groups = []
while deck_values:
  num_sf_groups <- read one integer
  groups = {}
  foreach num_sf_groups:
    num_cards <- read one integer
    g_set <- read one integer
    g_fac <- read one integer
    foreach num_cards:
      card_num <- read one integer
      groups[{g_set, g_fac}].push(card_num)
  quantity_groups.push(groups)

deck = {}
for i=quantity_groups.length, j=0; i >= 1; i--, j++:
  deck[i] = quantity_groups[j]
```

Currently, the official implementation hard-codes quantity groups 3-1[^15],
then checks for a special "extended" listing after group 1[^16].

If the spec ever changes to arbitrary groupings, you can do something
like:

```elixir
cards_int
│> Stream.unfold(fn
  [] -> nil
  ints -> decode_next_quantity_group(ints)
end)
│> Enum.reverse()
│> Stream.with_index(1)
│> Stream.map(fn {grp, cnt} -> {cnt, grp} end)
│> Map.new()
```

Essentially, expects groups quantities to be ordered in descending order
from highest to 1, with contiguous group identifiers. I.e., even if a
group quantity is empty, there must be a 0 to pad.

So something like `[1, 0, 0, 2, 1, 2]` would represent quantities of
6, 5, 4, 3, 2, 1, where 5 & 4 are empty. So long as they're in descending
order & contiguous, quantities can be of any size. And 0 padding is likely
reasonable since card quantities likely won't go larger than the 10s. But it
does allow for arbitrary expansion

### Encoding

Encoding is largely just the decoding process in reverse. However, there are
some notable specs to encoding to make it "stable." In general, encoding &
decoding deck codes should be cyclical, i.e. a deck code can be decoded and
re-encoded into the same code consistently, same goes for encoding and
re-decoding.
However, the decoding process isn't as strict as encoding process. It's possible
to decode a deck code that is re-encoded into a different code. This may
occur for a number of reasons.

1. The minimum version is different. The encoding process will determine the
   minimum version number necessary to properly support all cards in the deck.
   It's possible for the to-be-decoded code to have the wrong version, since
   it is not checked during the decoding process
2. The order of the card values are wrong. So long as the card values are
   ordered by quantity groups properly, the set/fac and number orders don't
   really matter for decoding. However, encoding expects a stable sort order.
   First by quantity, then by the number of cards in a set/fac group, then
   by the _alpha_ order of the _card codes_. This means when two or more
   set/fac groups have the same number of cards, they're ordered by the
   card codes. This means its sorted by set number, then faction _code_
   (not id), then card number.

You may not that the example code given above actually has an incorrect sort
order. The code was provided by the official library _before_ the card code
sort was done, so there wasn't guaranteed stability in that order.

## Notable deck codes

### Empty deck

The empty deck (for format v1) is `CEAAAAA`. We can break components down
like this:

```elixir
iex> use Bitwise, only_operators: true
iex> alias Riot.Util.Varint.LEB128
iex> format = 0b0001
1
iex> version = 0b0001
iex> prefix = (format <<< 4) ||| version
17
iex> card_count_groups = List.duplicate(0, 3)
iex> vals = [prefix | card_count_groups]
iex> vals
[17, 0, 0, 0]
iex> |> Enum.map(&LEB128.encode/1)
[<<17>>, <<0>>, <<0>>, <<0>>]
iex> |> Enum.into(<<>>)
<<17, 0, 0, 0>>
iex> |> Base.encode32(padding: false)
"CEAAAAA"
```

## Footnotes

[^1]: https://github.com/RiotGames/LoRDeckCodes/blob/52d10f702e98ca048fc241622e4c7e306d826919/README.md?plain=1#L24-L26

[^2]: https://github.com/RiotGames/LoRDeckCodes/blob/52d10f702e98ca048fc241622e4c7e306d826919/LoRDeckCodes/LoRDeckEncoder.cs#L144
[^3]: https://github.com/RiotGames/LoRDeckCodes/blob/52d10f702e98ca048fc241622e4c7e306d826919/LoRDeckCodes/LoRDeckEncoder.cs#L149-L151
[^4]: https://github.com/RiotGames/LoRDeckCodes/blob/52d10f702e98ca048fc241622e4c7e306d826919/LoRDeckCodes/LoRDeckEncoder.cs#L185-L191
[^5]: https://github.com/RiotGames/LoRDeckCodes/blob/52d10f702e98ca048fc241622e4c7e306d826919/LoRDeckCodes/LoRDeckEncoder.cs#L138

[^6]: https://github.com/RiotGames/LoRDeckCodes/blob/52d10f702e98ca048fc241622e4c7e306d826919/LoRDeckCodes/LoRDeckEncoder.cs#L78-L83

[^7]: https://github.com/RiotGames/LoRDeckCodes/blob/52d10f702e98ca048fc241622e4c7e306d826919/LoRDeckCodes/VarintTranslator.cs#L43-L66

[^8]: https://github.com/RiotGames/LoRDeckCodes/blob/ecfc259c7b03254e8b2776efdd4d15ea52b95f22/LoRDeckCodes/LoRDeckEncoder.cs#L81
[^9]: https://github.com/RiotGames/LoRDeckCodes/blob/ecfc259c7b03254e8b2776efdd4d15ea52b95f22/LoRDeckCodes/LoRDeckEncoder.cs#L17
[^10]: https://github.com/RiotGames/LoRDeckCodes/blob/ecfc259c7b03254e8b2776efdd4d15ea52b95f22/LoRDeckCodes/LoRDeckEncoder.cs#L149

[^11]: https://github.com/RiotGames/LoRDeckCodes/issues/47

[^12]: https://github.com/RiotGames/LoRDeckCodes/blob/52d10f702e98ca048fc241622e4c7e306d826919/LoRDeckCodes/Base32.cs#L39
[^13]: https://github.com/RiotGames/LoRDeckCodes/blob/52d10f702e98ca048fc241622e4c7e306d826919/LoRDeckCodes/Base32.cs#L104
[^14]: https://github.com/RiotGames/LoRDeckCodes/blob/52d10f702e98ca048fc241622e4c7e306d826919/LoRDeckCodes/Base32.cs#L146-L150

[^15]: https://github.com/RiotGames/LoRDeckCodes/blob/ecfc259c7b03254e8b2776efdd4d15ea52b95f22/LoRDeckCodes/LoRDeckEncoder.cs#L94-L112
[^16]: https://github.com/RiotGames/LoRDeckCodes/blob/ecfc259c7b03254e8b2776efdd4d15ea52b95f22/LoRDeckCodes/LoRDeckEncoder.cs#L115-L131

defmodule Riot.MixProject do
  use Mix.Project

  @source_url "https://github.com/ed-flanagan/riot_lor"
  @version "1.1.0"

  def project do
    [
      app: :riot_lor,
      version: @version,
      elixir: "~> 1.12",
      deps: deps(),

      # Hex
      package: package(),
      source_url: @source_url,

      # Docs
      name: "Riot LoR",
      description: "Riot LoR deck code library",
      docs: docs(),

      # Coverage
      # https://github.com/parroty/excoveralls#mixexs
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.24", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test, runtime: false},
      # NOTE: also `:dev` for formatter's `:import_deps`
      {:stream_data, "~> 0.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      maintainers: ["Ed Flanagan"],
      files: ~w(docs lib .formatter.exs CHANGELOG.md CONTRIBUTING.md LICENSE mix.exs)
    ]
  end

  defp docs do
    [
      main: "Riot.LoR.DeckCode",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: groups_for_modules(),
      markdown_processor: {ExDoc.Markdown.Earmark, footnotes: true}
    ]
  end

  defp extras() do
    [
      # Guides
      "docs/deck_codes.md",

      # General
      "CHANGELOG.md",
      "README.md": [title: "Readme"],
      "CONTRIBUTING.md": [title: "Contributing"]
    ]
  end

  defp groups_for_extras do
    [
      Guides: Path.wildcard("docs/*.md")
    ]
  end

  defp groups_for_modules do
    [
      LoR: [
        Riot.LoR.Card,
        Riot.LoR.Deck,
        Riot.LoR.DeckCode,
        Riot.LoR.Faction
      ],
      Util: [
        Riot.Util.Varint.LEB128,
        Riot.Util.Varint.VLQ
      ]
    ]
  end
end

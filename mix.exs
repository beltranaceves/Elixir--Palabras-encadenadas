defmodule WordChain.MixProject do
  use Mix.Project

  def project do
    [
      app: :word_chain,
      version: "0.1.0",
      elixir: "~> 1.10",
      build_embebbed: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :cowboy, :plug, :eex, :telemetry],
      mod: {WordChain.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.9"},
      {:plug_cowboy, "~> 2.5"},
      {:plug, "~> 1.11.1"},
      {:postgrex, "~> 0.15.7"},
      {:httpoison, "~> 1.8"},
      {:floki, "~> 0.30.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  # Run "mix docs" to generate application documentation.
  defp docs do
    [
      name: "WordChain",
      source_url: "https://github.com/UDC-FIC-AS/practica-final-proposta-propia-grupo-as-05",
      extras: ["README.md"],
      output: "./docs/html"
    ]
  end
end

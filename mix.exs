defmodule Chess.MixProject do
  use Mix.Project

  @description """
  Elixir package for playing chess game
  """

  def project do
    [
      app: :chess,
      version: "0.5.0",
      elixir: "~> 1.9",
      name: "Chess",
      description: @description,
      source_url: "https://github.com/kortirso/chess",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:floki, "~> 0.34.3", only: [:dev, :test]},
      {:httpoison, "~> 2.1", only: [:dev, :test]}
    ]
  end

  defp package do
    [
      maintainers: ["Anton Bogdanov"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/kortirso/chess"}
    ]
  end
end

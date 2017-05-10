defmodule Titticket.Mixfile do
  use Mix.Project

  def project do
    [app: :titticket,
     version: "0.1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [ extra_applications: [:logger],
      mod: { Titticket.Application, [] } ]
  end

  defp deps do
    [ { :urna,     "~> 0.2" },
      { :httprot,  "~> 0.1" },
      { :ecto,     "~> 2.1" },
      { :postgrex, "~> 0.13" },
      { :quantum,  ">= 1.9.1" },
      { :timex,    "~> 3.0" }]
  end
end

# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :titticket,
  ecto_repos: [Titticket.Repo]

# Configure titticket.
config :titticket,
  port:   8080,
  secret: "fill-me"

# Configure the database.
config :titticket, Titticket.Repo,
  adapter:  Ecto.Adapters.Postgres,
  database: "titticket",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

# Configure PayPal payments.
config :pay, :paypal,
  client_id: "fill-me",
  secret:    "fill-me",
  env:       :prod

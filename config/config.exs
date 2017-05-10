use Mix.Config
config :titticket,
  ecto_repos: [Titticket.Repo]

config :quantum, :titticket,
  cron: [
    "@hourly": &Titticket.Jobs.paypal/0
  ]

# Database configuration.
config :titticket, Titticket.Repo,
  adapter:  Ecto.Adapters.Postgres,
  database: "titticket",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

# Address and port to listen on.
config :titticket,
  host: "127.0.0.1",
  port: 8080,
  base: "https://example.com"

# Shared secret for authentication.
config :titticket,
  secret: "fill-me"

# Configure PayPal.
config :titticket, :paypal,
  currency: :EUR,

  success: "https://example.com/order/:order/executed",
  failure: "https://example.com/order/:order/cancelled",
  cancel:  "https://example.com/order/:order/cancel",

  id:     "fill-me",
  secret: "fill-me",

  sandbox: [
    id:     "fill-me",
    secret: "fill-me",
  ]

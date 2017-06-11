use Mix.Config
alias Titticket.{Repo, V1, Mailer, Jobs, Authorization, Pay}

# Address and port to listen on.
config :titticket, V1,
  host: "127.0.0.1",
  port: 3000,
  base: "https://example.com"

# Shared secret for authentication.
config :titticket, Authorization,
  secret: "fill-me"

# Database configuration.
config :titticket,
  ecto_repos: [Repo]

config :titticket, Repo,
  adapter:  Ecto.Adapters.Postgres,
  database: "titticket",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

# Internal jobs.
config :quantum, :titticket,
  cron: [
    "@hourly": &Jobs.cash/0,
    "@hourly": &Jobs.wire/0,
    "@hourly": &Jobs.paypal/0
  ]

# Mailer configuration.
config :titticket, Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "mail.example.com",
  port: 25,
  username: "user",
  password: "password",
  tls: :if_available,
  ssl: false,
  retries: 3

# Configure PayPal.
config :titticket, Pay.Paypal,
  currency: :EUR,

  success: "https://example.com/order/:order/success",
  failure: "https://example.com/order/failure",
  cancel:  "https://example.com/order/cancel",

  id:     "fill-me",
  secret: "fill-me",

  sandbox: [
    id:     "fill-me",
    secret: "fill-me",
  ]

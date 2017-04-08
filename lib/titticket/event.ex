defmodule Titticket.Event do
  use Ecto.Schema

  schema "events" do
    field :opens, :date
    field :closes, :date

    field :title, :string
    field :description, :string
    field :state, Titticket.State

    has_many :tickets, Titticket.Ticket
  end
end

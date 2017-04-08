defmodule Titticket.Ticket do
  use Ecto.Schema

  schema "tickets" do
    field :opens, :date
    field :closes, :date

    field :title, :string
    field :description, :string
    field :state, Titticket.State

    field :amount, :integer
    field :payment, { :array, :map }
    field :questions, { :array, :map }

    belongs_to :event, Titticket.Event
    has_many :reservations, Titticket.Reservation
    has_many :purchases, Titticket.Purchase
  end
end

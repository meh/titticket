defmodule Titticket.Purchase do
  use Ecto.Schema

  schema "purchases" do
    field :at, :utc_datetime

    field :type, Titticket.Purchase.Type
    field :details, :map
    field :answers, { :array, :map }

    belongs_to :ticket, Titticket.Ticket
  end
end

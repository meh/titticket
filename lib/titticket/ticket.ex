#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Ticket do
  use Ecto.Schema
  use Titticket.Changeset

  schema "tickets" do
    timestamps()

    field :opens, :date
    field :closes, :date

    field :title, :string
    field :description, :string
    field :status, Titticket.Status

    field :amount, :integer
    field :payment, { :array, Titticket.Payment }
    field :questions, { :array, Titticket.Question }

    belongs_to :event, Titticket.Event
    has_many :purchases, Titticket.Purchase
  end

  def create(event, params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:opens, :closes, :title, :description, :status, :amount, :payment, :questions])
    |> validate_required([:title, :status, :payment])
    |> put_assoc(:event, event)
  end
end

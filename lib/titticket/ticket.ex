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

  alias __MODULE__
  alias Titticket.{Status, Payment, Question, Event, Purchase}

  schema "tickets" do
    timestamps()

    field :opens, :date
    field :closes, :date

    field :title, :string
    field :description, :string
    field :status, Status, default: :suspended

    field :amount, :integer
    field :payment, { :array, Payment }
    field :questions, { :map, Question }

    belongs_to :event, Event
    has_many :purchases, Purchase
  end

  def create(event, params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:opens, :closes, :title, :description, :status, :amount, :payment])
    |> cast_questions(params["questions"])
    |> validate_required([:title, :payment])
    |> put_assoc(:event, event)
  end

  def change(ticket, params \\ %{}) do
    ticket
    |> cast(params, [:opens, :closes, :title, :description, :status, :amount, :payment, :questions])
  end

  def purchases(ticket) do
    import Ecto.Query

    from p in Purchase,
      where:  p.ticket_id == ^ticket.id,
      select: count(p.id)
  end
end

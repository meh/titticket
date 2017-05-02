#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Event do
  use Ecto.Schema
  use Titticket.Changeset
  alias Titticket.{Status, Ticket}

  schema "events" do
    timestamps()

    field :opens, :date
    field :closes, :date

    field :title, :string
    field :description, :string
    field :status, Status, default: :suspended

    has_many :tickets, Ticket
  end

  def create(params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:opens, :closes, :title, :description, :status])
    |> validate_required([:opens, :title])
  end

  def change(event, params \\ {}) do
    event
    |> cast(params, [:opens, :closes, :title, :description, :status])
  end

  def tickets(event) do
    import Ecto.Query

    from t in Ticket,
      where:  t.event_id == ^event.id,
      select: t.id
  end
end

defmodule Titticket.Event do
  use Ecto.Schema
  use Titticket.Changeset

  schema "events" do
    timestamps()

    field :opens, :date
    field :closes, :date

    field :title, :string
    field :description, :string
    field :status, Titticket.Status

    has_many :tickets, Titticket.Ticket
  end

  def create(params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:opens, :closes, :title, :description, :status])
    |> validate_required([:opens, :title, :status])
  end
end

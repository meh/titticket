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

  alias __MODULE__
  alias Titticket.{Repo, Status, Ticket, Order, Authorization}

  schema "events" do
    timestamps()

    field :opens, :date
    field :closes, :date

    field :title, :string
    field :description, :string
    field :status, Status, default: :suspended

    has_many :tickets, Ticket
    has_many :orders, Order
  end

  @type t :: %__MODULE__{}

  @spec output(t, Authorization.t, Authorization.t) :: map
  def output(event, tickets, orders) do
    tickets = if tickets == :authorized do
      Repo.all(tickets(event))
    end

    orders = if orders == :authorized do
      Repo.all(orders(event))
    end

    { :ok, %{
      id:      event.id,
      tickets: tickets,
      orders:  orders,

      opens:  event.opens,
      closes: event.closes,

      title:       event.title,
      description: event.description,
      status:      event.status } }
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

  def available do
    import Ecto.Query

    from t in Event,
      where: t.status != ^:inactive
  end

  def tickets(event) do
    import Ecto.Query

    from t in Ticket,
      where:  t.event_id == ^event.id and t.status != ^:inactive,
      select: t.id
  end

  def orders(event) do
    import Ecto.Query

    from o in Order,
      where:  o.event_id == ^event.id,
      select: o.id
  end
end

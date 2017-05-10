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
  alias Titticket.{Repo, Status, Ticket, Order, Authorization, Question}

  schema "events" do
    timestamps()

    field :opens, :date
    field :closes, :date

    field :title, :string
    field :description, :string
    field :links, { :array, Event.Link }
    field :status, Status, default: :suspended

    field :questions, { :map, Question }

    has_many :tickets, Ticket
    has_many :orders, Order
  end

  @type t :: %__MODULE__{}

  @spec output(t, Authorization.t, Authorization.t) :: map
  def output(event, tickets, orders) do
    with { :ok, questions } <- Question.unflatten(event.questions),
         tickets            <- if(tickets == :authorized, do: Repo.all(tickets(event))),
         orders             <- if(orders == :authorized, do: Repo.all(orders(event)))
    do
      { :ok, %{
        id:      event.id,
        tickets: tickets,
        orders:  orders,

        opens:  event.opens,
        closes: event.closes,

        title:       event.title,
        description: event.description,
        links:       event.links,
        status:      event.status,

        questions: questions } }
    else
      :error ->
        :error
    end
  end

  def create(params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:opens, :closes, :title, :description, :links, :status])
    |> cast_questions(params["questions"])
    |> validate_required([:opens, :title])
  end

  def update(event, params \\ {}) do
    event
    |> cast(params, [:opens, :closes, :title, :description, :links, :status])
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

  def people(event) do
    import Ecto.Query

    from o in Order,
      distinct: true,
      where:    o.event_id == ^event.id and not o.private,
      order_by: o.identifier,
      select:   [o.identifier, o.confirmed]
  end
end

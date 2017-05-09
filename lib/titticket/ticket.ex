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
  alias Titticket.{Repo, Status, Payment, Question, Event, Purchase}

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

  @type t :: %__MODULE__{}

  @spec output(t) :: map
  def output(ticket) do
    prepare = fn questions ->
      Question.unflatten questions, fn %Question{ id: id, amount: amount } = question ->
        case Question.dump(question) do
          { :ok, question } ->
            question = if amount do
              question |> Map.put("amount", %{
                purchased: Repo.one(Question.purchases(id)),
                max:       amount })
            else
              question
            end

            { :ok, question }

          :error ->
            :error
        end
      end
    end

    with { :ok, status }    <- Ecto.Type.dump(Status, ticket.status),
         { :ok, payment }   <- Ecto.Type.dump({ :array, Payment }, ticket.payment),
         { :ok, questions } <- prepare.(ticket.questions),
         purchases          <- Repo.one(purchases(ticket))
    do
      { :ok, %{ id:    ticket.id,
         event: ticket.event_id,

         opens:  ticket.opens || ticket.event.opens,
         closes: ticket.closes || ticket.event.closes,

         title:       ticket.title,
         description: ticket.description,
         status:      status,

         amount:    if(ticket.amount, do: %{purchased: purchases, max: ticket.amount}),
         payment:   payment,
         questions: questions } }
    else
      :error ->
        :error
    end
  end

  def create(event, params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:opens, :closes, :title, :description, :status, :amount, :payment])
    |> cast_questions(params["questions"])
    |> validate_required([:title, :payment])
    |> put_assoc(:event, event)
  end

  def update(ticket, params \\ %{}) do
    ticket
    |> cast(params, [:opens, :closes, :title, :description, :status, :amount])
  end

  def purchases(ticket) do
    import Ecto.Query

    from p in Purchase,
      where:  p.ticket_id == ^ticket.id,
      select: count(p.id)
  end
end

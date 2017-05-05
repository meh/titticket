#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Purchase do
  use Ecto.Schema
  use Titticket.Changeset

  alias Titticket.{Ticket, Payment, Answer, Order}

  @primary_key { :id, Ecto.UUID, autogenerate: true }
  schema "purchases" do
    timestamps()

    field :answers, { :map, Answer }

    belongs_to :ticket, Ticket
    belongs_to :order, Order, type: Ecto.UUID
  end

  def create(order, ticket, params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [])
    |> cast_answers(params["answers"])
    |> validate_answers(:answers, ticket.questions)
    |> put_assoc(:order, order)
    |> put_assoc(:ticket, ticket)
  end

  def change(purchase, params \\ %{}) do
    purchase
    |> cast(params, [:confirmed])
  end

  def total(purchase) do
    total(purchase, purchase.order.payment.type)
  end

  def total(purchase, payment) do
    payment = purchase.ticket.payment
      |> Enum.find(&(&1.type == payment))

    total = if payment.price.beyond && Date.compare(Date.utc_today, payment.price.beyond.date) == :gt do
      payment.price.beyond.value
    else
      payment.price.value
    end

    Enum.reduce purchase.answers, total, fn { id, _ }, total ->
      question = purchase.ticket.questions[id]

      if question.price do
        total |> Decimal.add(question.price)
      else
        total
      end
    end
  end
end

#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Order do
  use Ecto.Schema
  use Titticket.Changeset

  alias Titticket.{Event, Purchase, Payment}

  @primary_key { :id, :binary_id, autogenerate: true }
  schema "orders" do
    timestamps()

    field :confirmed, :boolean, default: false
    field :payment, Payment.Details

    belongs_to :event, Event
    has_many :purchases, Purchase
  end

  def create(event, params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:confirmed, :payment])
    |> put_assoc(:event, event)
  end

  def confirm(order) do
    order
    |> change(%{ confirmed: true })
  end

  def payment(order, payment) do
    order
    |> change(%{ payment: payment })
  end

  def total(order) do
    total(order, order.payment.type)
  end

  def total(order, payment) do
    Enum.reduce order.purchases, Decimal.new(0),
      &Decimal.add(Purchase.total(&1, payment), &2)
  end
end

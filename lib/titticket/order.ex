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

  alias __MODULE__
  alias Titticket.{Event, Purchase, Payment}

  @primary_key { :id, Ecto.UUID, autogenerate: true }
  schema "orders" do
    timestamps()

    field :confirmed, :boolean, default: false
    field :payment, Payment.Details

    belongs_to :event, Event
    has_many :purchases, Purchase, on_delete: :delete_all
  end

  def create(event, params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:confirmed, :payment])
    |> put_assoc(:event, event)
  end

  def update(order, params \\ %{}) do
    order     = order |> change(%{})
    confirmed = params["confirmed"]
    details   = params["details"]

    order = if is_boolean(confirmed) do
      order |> put_change(:confirmed, confirmed)
    else
      order
    end

    order = if is_map(details) do
      order |> put_change(:payment, %Payment.Details{ order.payment | details: details })
    else
      order
    end

    order
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

  def for_paypal(id) when is_binary(id) do
    import Ecto.Query

    from o in Order,
      where: fragment(~s[? #> '{details,id}' = ?], o.payment, ^id) and
             fragment(~s[? -> 'type' = ?], o.payment, ^:paypal)
  end
end

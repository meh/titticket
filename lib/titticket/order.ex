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
  alias Titticket.{Event, Purchase, Payment, Answer}

  @primary_key { :id, Ecto.UUID, autogenerate: true }
  schema "orders" do
    timestamps()

    field :identifier, :string
    field :email, :string
    field :private, :boolean, default: false
    field :confirmed, :boolean, default: false

    field :payment, Payment.Details
    field :answers, { :map, Answer }

    belongs_to :event, Event
    has_many :purchases, Purchase, on_delete: :delete_all
  end

  def create(event, params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:identifier, :email, :private, :confirmed, :payment])
    |> validate_required([:identifier, :email])
    |> cast_answers(params["answers"])
    |> validate_answers(:answers, event.questions)
    |> put_assoc(:event, event)
  end

  def update(order, params \\ %{}) do
    updated = order |> cast(params, [:identifier, :email, :private, :confirmed])

    updated = if is_map(params["payment"] || params[:payment]) do
      updated |> put_change(:payment, %Payment.Details{ order.payment |
        details: params["payment"] || params[:payment] })
    else
      updated
    end

    updated
  end

  def total(order) do
    total(order, order.payment.type)
  end

  def total(order, payment) do
    Enum.reduce order.purchases, Decimal.new(0),
      &Decimal.add(Purchase.total(&1, payment), &2)
  end

  def paypal(id) when is_binary(id) do
    import Ecto.Query

    from o in Order,
      where: fragment(~s[? #> '{details,id}' = ?], o.payment, ^id) and
             fragment(~s[? -> 'type' = ?], o.payment, ^:paypal)
  end

  def paypal(token: token) when is_binary(token) do
    import Ecto.Query

    from o in Order,
      where: fragment(~s[? #> '{details,token}' = ?], o.payment, ^token) and
             fragment(~s[? -> 'type' = ?], o.payment, ^:paypal)
  end

  def unconfirmed do
    import Ecto.Query

    from o in Order,
      where: not o.confirmed
  end

  def unconfirmed(:paypal) do
    import Ecto.Query

    from o in Order,
      where: fragment(~s[? -> 'type' = ?], o.payment, ^:paypal) and not o.confirmed
  end
end

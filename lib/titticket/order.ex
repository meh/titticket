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
    field :status, Order.Status, default: :created

    field :payment, Payment.Details
    field :answers, { :map, Answer }

    belongs_to :event, Event
    has_many :purchases, Purchase, on_delete: :delete_all
  end

  def create(event, params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:identifier, :email, :private, :status, :payment])
    |> validate_required([:identifier, :email])
    |> cast_answers(params["answers"])
    |> validate_answers(:answers, event.questions)
    |> put_assoc(:event, event)
  end

  def update(order, params \\ %{}) do
    updated = order |> cast(params, [:identifier, :email, :private, :status])

    updated = if is_map(params["payment"] || params[:payment]) do
      updated |> put_change(:payment, %Payment.Details{ order.payment |
        details: params["payment"] || params[:payment] })
    else
      updated
    end

    updated
  end

  def payment(order, :paypal, response) do
    id          = response["id"]
    transaction = Enum.at(response["transactions"], 0)
    resources   = transaction["related_resources"]
    sale        = Enum.find(resources, &(&1["sale"]))["sale"]["id"]
    payer       = response["payer"]["payer_info"]["payer_id"]

    order |> update(%{
      payment:   %{
        id:    id,
        sale:  sale,
        payer: payer } })
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

  def paypal(token: token) do
    import Ecto.Query

    from o in Order,
      where: fragment(~s[? #> '{details,token}' = ?], o.payment, ^token) and
             fragment(~s[? -> 'type' = ?], o.payment, ^:paypal)
  end

  def paypal(sale: sale) do
    import Ecto.Query

    from o in Order,
      where: fragment(~s[? #> '{details,sale}' = ?], o.payment, ^sale) and
             fragment(~s[? -> 'type' = ?], o.payment, ^:paypal)
  end

  def paypal(payer: payer) do
    import Ecto.Query

    from o in Order,
      where: fragment(~s[? #> '{details,payer}' = ?], o.payment, ^payer) and
             fragment(~s[? -> 'type' = ?], o.payment, ^:paypal)
  end

  def pending do
    import Ecto.Query

    from o in Order,
      where: not o.status == ^:pending
  end

  def pending(:paypal) do
    import Ecto.Query

    from o in Order,
      where: fragment(~s[? -> 'type' = ?], o.payment, ^:paypal) and o.status in ^[:created, :pending]
  end
end

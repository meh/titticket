defmodule Titticket.Pay.Paypal.Payment do
  use HTTProt
  import Titticket.Pay.Paypal.Agent

  alias Titticket.{V1, Order, Purchase}
  alias Titticket.Pay.Paypal

  @doc """
  Request a new payment.
  """
  def create(order) do
    currency = Application.get_env(:titticket, Paypal)[:currency]
    total    = Order.total(order, :paypal)

    HTTP.post("#{url}/payments/payment", Poison.encode!(%{
      intent: :sale,
      payer:  %{payment_method: :paypal},

      transactions: [%{
        description: order.event.title |> String.slice(0, 127),

        item_list: %{
          items: Enum.map(order.purchases, fn purchase ->
            %{ quantity:    1,
               price:       Purchase.total(purchase, :paypal),
               currency:    currency,
               name:        purchase.ticket.title |> String.slice(0, 127),
               description: purchase.ticket.description |> String.slice(0, 127) }
          end) },

        amount: %{
          currency: currency,
          details:  %{ tax: "0", subtotal: total },
          total:    total } }],

      redirect_urls: %{
        return_url: "#{Application.get_env(:titticket, V1)[:base]}/v1/pay/paypal/done",
        cancel_url: "#{Application.get_env(:titticket, V1)[:base]}/v1/pay/paypal/cancel" }
    }), headers) |> parse
  end

  def create!(price) do
    create(price) |> bang
  end

  @doc """
  Get the status of a payment.
  """
  def status(id) do
    HTTP.get("#{url}/payments/payment/#{id}", headers) |> parse
  end

  def status!(id) do
    status(id) |> bang
  end

  @doc """
  Finalize a payment.
  """
  def execute(id, payer) do
    HTTP.post("#{url}/payments/payment/#{id}/execute", Poison.encode!(%{
      payer_id: payer }), headers) |> parse
  end

  def execute!(id, payer) do
    execute(id, payer) |> bang
  end
end

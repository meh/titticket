defmodule Titticket.Jobs do
  require Logger
  alias Titticket.{Repo, Order, Pay}

  def paypal do
    Enum.each Repo.all(Order.unconfirmed(:paypal)), fn order ->
      status = Pay.Paypal.status(order.payment["details"]["id"])

      case status do
        # The payment is being approved.
        "created" ->
          nil

        # The payment was approved but the redirect failed.
        "approved" ->
          Logger.info "PayPal payment executed for order #{order.id}"

          Repo.update!(order
            |> Order.update(%{ confirmed: true }))

        # The payment failed, remove the order.
        "failed" ->
          Logger.error "PayPal payment failed for order #{order.id}"

          Repo.delete!(order)
      end
    end
  end
end

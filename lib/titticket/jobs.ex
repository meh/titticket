defmodule Titticket.Jobs do
  require Logger
  alias Titticket.{Repo, Order, Pay}

  def paypal do
    Enum.each Repo.all(Order.unconfirmed(:paypal)), fn order ->
      response = Pay.Paypal.status!(order.payment.details["id"])

      case response["state"] do
        # The payment is being approved, removed the order if it expired.
        "created" ->
          updated = DateTime.to_unix(DateTime.from_naive!(order.updated_at, "Etc/UTC"))
          now     = DateTime.to_unix(DateTime.utc_now)

          if now - updated > 60 * 60 do
            Logger.error "PayPal payment failed for order #{order.id}"
            Repo.delete!(order)
          end

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

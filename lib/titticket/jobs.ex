defmodule Titticket.Jobs do
  require Logger
  alias Titticket.{Repo, Order, Pay}

  def paypal do
    Enum.each Repo.all(Order.unconfirmed(:paypal)), fn order ->
      payment  = order.payment.details["id"]
      response = Pay.Paypal.status!(payment)
      payer    = response["payer"]["payer_info"]["payer_id"]

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
          case Pay.Paypal.execute(payment, payer) do
            # Execution successful.
            { :ok, %{ "state" => "approved" } = response } ->
              Logger.info "PayPal payment executed for order #{order.id}"

              Repo.update!(order
                |> Order.update(%{ confirmed: true, payment: %{
                  id:    payment,
                  payer: response["payer"] } }))

            # Execution failed.
            { :ok, %{ "state" => "failed" } = response } ->
              Logger.error "PayPal payment failed for order #{order.id} because #{response["failure_reason"]}"

              Repo.delete!(order)

            # Network error.
            { :error, reason } ->
              Logger.error "PayPal network error for order #{order.id} (#{inspect(reason)})"

            # PayPal error.
            { :error, code, reason } ->
              Logger.error "PayPal payment error for order #{order.id} (#{code} #{inspect(reason)})"
          end

        # The payment failed, remove the order.
        "failed" ->
          Logger.error "PayPal payment failed for order #{order.id}"

          Repo.delete!(order)
      end
    end
  end
end

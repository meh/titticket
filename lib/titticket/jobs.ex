#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Jobs do
  require Logger
  alias Titticket.{Repo, Order, Pay}

  def paypal do
    Enum.each Repo.all(Order.pending(:paypal)), fn order ->
      spawn fn ->
        payment  = order.payment.details["id"]
        response = Pay.Paypal.Payment.status!(payment)
        payer    = response["payer"]["payer_info"]["payer_id"]

        case response["state"] do
          # The payment is being approved, removed the order if it expired.
          "created" ->
            updated = DateTime.to_unix(DateTime.from_naive!(order.updated_at, "Etc/UTC"))
            now     = DateTime.to_unix(DateTime.utc_now)

            if now - updated > 60 * 60 do
              Logger.error "PayPal payment timed out for order #{order.id}", pay: :paypal
              Repo.delete!(order)
            end

          # The payment was approved but the redirect failed.
          "approved" ->
            case Pay.Paypal.Payment.execute(payment, payer) do
              # Execution successful.
              { :ok, %{ "state" => "approved" } = response } ->
                Logger.info "PayPal payment executed for order #{order.id}", pay: :paypal
                Repo.update!(order |> Order.payment(:paypal, response))

              # Execution failed.
              { :ok, %{ "state" => "failed" } = response } ->
                Logger.error "PayPal payment failed for order #{order.id} because #{response["failure_reason"]}", pay: :paypal
                Repo.delete!(order)

              # Network error.
              { :error, reason } ->
                Logger.error "PayPal network error for order #{order.id} (#{inspect(reason)})", pay: :paypal

              # PayPal error.
              { :error, code, reason } ->
                Logger.error "PayPal payment error for order #{order.id} (#{code} #{inspect(reason)})", pay: :paypal
            end

          # The payment failed, remove the order.
          "failed" ->
            Logger.error "PayPal payment failed for order #{order.id}", pay: :paypal
            Repo.delete!(order)
        end
      end
    end
  end
end

#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.V1 do
  use Urna,
    allow:    [headers: true, methods: true, credentials: true],
    adapters: [Urna.JSON, Urna.Form]

  require Logger
  alias Titticket.{Repo, Changeset, Event, Ticket, Order, Purchase, Payment, Question}
  alias Titticket.{Pay, Mailer}
  import Titticket.Authorization

  namespace :v1 do
    resource :query do
      resource :event do
        get do
          case query("q") do
            nil ->
              with :authorized <- can?({ :query, :event }) do
                Enum.map Repo.all(Event.available), fn event ->
                  with { :ok, output } <- Event.output(event,
                                                       can?({ :see, :event, event.id, :tickets }),
                                                       can?({ :see, :event, event.id, :orders }))
                  do
                    output
                  end
                end
              else
                :unauthorized ->
                  fail 401
              end

            "people" ->
              with id when is_binary(id)   <- query("id"),
                   { id, _ }               <- Integer.parse(id),
                   :authorized             <- can?({ :query, :event, id, :people }),
                   event when event != nil <- Repo.get(Event, id)
              do
                Enum.map Repo.all(Event.people(event)), fn [name, status, at] ->
                  %{ name: name, status: status, at: at }
                end
              else
                :unauthorized ->
                  fail 401

                nil ->
                  fail 404

                _ ->
                  fail 422
              end

            _ ->
              fail 422
          end
        end
      end
    end

    resource :event do
      # Get an event.
      get id, as: Integer do
        with :authorized             <- can?({ :see, :event, id }),
             event when event != nil <- Repo.get(Event, id),
             { :ok, output }         <- Event.output(event,
                                                     can?({ :see, :event, event.id, :tickets }),
                                                     can?({ :see, :event, event.id, :orders }))
        do
          output
        else
          :unauthorized ->
            fail 401

          nil ->
            fail 404
        end
      end

      # Create an event.
      post do
        Repo.transaction! fn ->
          with :authorized    <- can?({ :create, :event }),
               { :ok, event } <- Repo.insert(Event.create(params()))
          do
            event.id
          else
            :unauthorized ->
              Repo.rollback(fail 401)

            { :error, changeset } ->
              Repo.rollback(fail Changeset.errors(changeset), 422)
          end
        end
      end

      # Change an event.
      patch id, as: Integer do
        Repo.transaction! fn ->
          with :authorized             <- can?({ :change, :event, id }),
               event when event != nil <- Repo.get(Event, id),
               { :ok, event }          <- Repo.update(event |> Event.update(params()))
          do
            event.id
          else
            :unauthorized ->
              Repo.rollback(fail 401)

            nil ->
              Repo.rollback(fail 404)

            { :error, changeset } ->
              Repo.rollback(fail Changeset.errors(changeset), 422)
          end
        end
      end

      # Delete an event.
      delete id, as: Integer do
        Repo.transaction! fn ->
          with :authorized             <- can?({ :delete, :event, id }),
               event when event != nil <- Repo.get(Event, id),
               { :ok, event }          <- Repo.delete(event)
          do
            event.id
          else
            :unauthorized ->
              Repo.rollback(fail 401)

            { :error, changeset } ->
              Repo.rollback(fail Changeset.errors(changeset), 422)

            nil ->
              Repo.rollback(fail 404)
          end
        end
      end
    end

    resource :ticket do
      # Get a ticket.
      get id, as: Integer do
        with :authorized               <- can?({ :see, :ticket, id }),
             ticket when ticket != nil <- Repo.get(Ticket, id) |> Repo.preload(:event),
             { :ok, output }           <- Ticket.output(ticket)
        do
          output
        else
          :error ->
            fail 500

          nil ->
            fail 404
        end
      end

      # Create a new ticket.
      post do
        Repo.transaction! fn ->
          with :authorized             <- can?({ :create, :ticket }),
               event when event != nil <- Repo.get(Event, param("event")),
               { :ok, ticket }         <- Repo.insert(Ticket.create(event, params()))
          do
            ticket.id
          else
            :unauthorized ->
              Repo.rollback(fail 401)

            { :error, changeset } ->
              Repo.rollback(fail Changeset.errors(changeset), 422)

            nil ->
              Repo.rollback(fail 404)
          end
        end
      end

      # Change a ticket.
      patch id, as: Integer do
        Repo.transaction! fn ->
          with :authorized               <- can?({ :change, :ticket, id }),
               ticket when ticket != nil <- Repo.get(Ticket, id),
               0                         <- Ticket.purchases(ticket),
               { :ok, ticket }           <- Repo.update(ticket |> Ticket.update(params()))
          do
            ticket.id
          else
            :unauthorized ->
              Repo.rollback(fail 401)

            nil ->
              Repo.rollback(fail 404)

            { :error, changeset } ->
              Repo.rollback(fail Changeset.errors(changeset), 422)
          end
        end
      end

      # Delete a ticket.
      delete id, as: Integer do
        Repo.transaction! fn ->
          with :authorized               <- can?({ :delete, :ticket, id }),
               ticket when ticket != nil <- Repo.get(Ticket, id),
               { :ok, ticket }           <- Repo.delete(ticket)
          do
            ticket.id
          else
            :unauthorized ->
              Repo.rollback(fail 401)

            { :error, changeset } ->
              Repo.rollback(fail Changeset.errors(changeset), 422)

            nil ->
              Repo.rollback(fail 404)
          end
        end
      end
    end

    resource :order do
      # Get an order.
      get id do
        with :authorized             <- can?({ :see, :order, id }),
             order when order != nil <- Repo.get(Order, id) |> Repo.preload([:event, purchases: [:ticket, :order]])
        do
          %{ id:    order.id,
             event: order.event_id,

             total:      Order.total(order),
             identifier: if(:authorized == can?({ :see, :order, order.id, :identifier }), do: order.identifier),
             email:      if(:authorized == can?({ :see, :order, order.id, :email }), do: order.email),
             status:     order.status,
             answers:    Enum.map(order.answers, fn { id, answer } ->
               if !order.event.questions[id].private ||
                  :authorized == can?({ :see, :order, order.id, :answers })
               do
                 answer
               end
             end) |> Enum.reject(&(&1 == nil)),

             purchases: Enum.map(order.purchases, fn purchase ->
               %{ ticket:  purchase.ticket_id,
                  total:   Purchase.total(purchase),
                  answers: Enum.map(purchase.answers, fn { id, answer } ->
                    if !purchase.ticket.questions[id].private ||
                       :authorized == can?({ :see, :purchase, purchase.id, :answers })
                    do
                      answer
                    end
                  end) |> Enum.reject(&(&1 == nil)) }
             end) }
        else
          :unauthorized ->
            fail 401

          nil ->
            fail 404
        end
      end

      # Create a new order.
      post do
        Repo.transaction! fn ->
          # Check if a purchase is available based on its answers.
          available = fn purchase ->
            result = Enum.find purchase.answers, fn { id, _ } ->
              question = purchase.ticket.questions[id]

              if question.amount do
                question.amount < Repo.one(Question.purchases(id))
              end
            end

            unless result, do: { :ok, purchase }, else: :error
          end

          # Create purchases.
          purchases = fn event, order, tickets ->
            try do
              purchases = Enum.map tickets, fn current ->
                with ticket when ticket != nil <- Repo.get(Ticket, current["id"]),
                     :ok                       <- if(Enum.find(ticket.payment, &(&1.type == order.payment.type)), do: :ok, else: :no_payment),
                     true                      <- ticket.event_id == event.id,
                     :active                   <- ticket.status || event.status,
                     { :ok, purchase }         <- Repo.insert(Purchase.create(order, ticket, current)),
                     { :ok, purchase }         <- available.(purchase)
                do
                  purchase
                else
                  error when error in [:inactive, :suspended] ->
                    throw { :error, [{ :status, "ticket is not active" }] }

                  nil ->
                    throw { :error, [{ :ticket, "no ticket found" }] }

                  false ->
                    throw { :error, [{ :event, "mismatching event" }] }

                  { :error, changeset } ->
                    throw { :error, changeset.errors }

                  :error ->
                    throw { :error, [{ :ticket, "ticket unavailable" }] }

                  :no_payment ->
                    throw { :error, [{ :payment, "payment type not available" }] }
                end
              end

              { :ok, purchases }
            catch
              error ->
                error
            end
          end

          with :authorized             <- can?({ :create, :order, param("event") }),
               event when event != nil <- Repo.get(Event, param("event")),
               :active                 <- event.status,
               { :ok, order }          <- Repo.insert(Order.create(event, params())),
               { :ok, _ }              <- purchases.(event, order, param("tickets"))
          do
            { action, details } = case order.payment.type do
              :cash ->
                { %{ redirect: "#{Application.get_env(:titticket, __MODULE__)[:base]}/v1/pay/cash/done?id=#{order.id}" },
                  %{} }

              :wire ->
                id = Pay.Wire.unique

                { %{ redirect: "#{Application.get_env(:titticket, __MODULE__)[:base]}/v1/pay/wire/done?id=#{id}" },
                  %{ id: id } }

              :paypal ->
                response = Pay.Paypal.Payment.create!(order |> Repo.preload([:event, purchases: :ticket]))
                approval = Enum.find(response["links"], &(&1["rel"] == "approval_url"))["href"]

                { %{ redirect: approval },
                  %{ id: response["id"], token: URI.decode_query(URI.parse(approval).query)["token"] } }
            end

            order = Repo.update!(order
              |> Order.update(%{ payment: details }))

            %{ order:  order.id,
               action: action }
          else
            :unauthorized ->
              Repo.rollback(fail 401)

            nil ->
              Repo.rollback(fail 404)

            :error ->
              Repo.rollback(fail 422)

            { :error, errors } ->
              Repo.rollback(fail Changeset.errors(errors), 422)

            error when error in [:inactive, :suspended] ->
              Repo.rollback(fail Changeset.errors([{ :status, "ticket is not active" }]), 422)
          end
        end, timeout: :infinity
      end

      # Confirm a manual order.
      patch id do
        manual? = fn order ->
          order.payment.type != :paypal
        end

        Repo.transaction! fn ->
          with :authorized             <- can?({ :change, :order, id }),
               order when order != nil <- Repo.get(Order, id),
               true                    <- manual?.(order),
               { :ok, order }          <- Repo.update(order |> Order.update(params()))
          do
            order.id
          else
            :unauthorized ->
              Repo.rollback(fail 401)

            false ->
              Repo.rollback(fail 401)

            nil ->
              Repo.rollback(fail 404)

            { :error, changeset } ->
              Repo.rollback(fail Changeset.errors(changeset), 422)
          end
        end
      end

      # Delete an order.
      delete id do
        Repo.transaction! fn ->
          with :authorized             <- can?({ :delete, :order, id }),
               order when order != nil <- Repo.get(Order, id),
               { :ok, order }          <- Repo.delete(order)
          do
            order.id
          else
            :unauthorized ->
              Repo.rollback(fail 401)

            { :error, changeset } ->
              Repo.rollback(fail Changeset.errors(changeset), 422)

            nil ->
              Repo.rollback(fail 404)
          end
        end
      end
    end

    # Payment integration.
    namespace :pay do
      namespace :cash do
        resource :done do
          get do
            id    = query("id")
            order = Repo.get!(Order, id)

            if order.status != :created do
              fail 401
            else
              Logger.info "Cash payment created"

              if mail = order.event.configuration.mail do
                mail |> Event.Mail.new(order.email, order: order) |> Mailer.deliver_later
              end

              redirect String.replace(
                Application.get_env(:titticket, Pay.Cash)[:done],
                ":order",
                to_string(order.id))
            end
          end

        end

        resource :confirm do
          get do
            id    = query("id")
            order = Repo.get!(Order, id)

            if order.status != :created do
              fail 401
            else
              Logger.info "Cash payment confirmed"

              Repo.update!(order |> Order.update(%{ status: :pending }))

              redirect String.replace(
                Application.get_env(:titticket, Pay.Cash)[:done],
                ":order",
                to_string(order.id))
            end
          end
        end
      end

      namespace :wire do
        resource :done do
          get do
            order = Repo.one!(Order.wire(query("id")))
              |> Repo.preload([:event, purchases: :ticket])

            if order.status != :created do
              fail 401
            else
              Repo.update!(order |> Order.update(%{ status: :pending }))

              if mail = order.event.configuration.mail do
                mail |> Event.Mail.new(order.email, order: order) |> Mailer.deliver_later
              end

              redirect String.replace(
                Application.get_env(:titticket, Pay.Wire)[:done],
                ":order",
                to_string(order.id))
            end
          end
        end

        resource :confirm do
          post do
            order = Repo.one!(Order.wire(query("id")))

            if order.status != :pending || can?({ :confirm, :order, order.id }) != :authorized do
              fail 401
            else
              Repo.update!(order
                |> Order.update(%{ status: :paid }))

              reply 204
            end
          end
        end
      end

      namespace :paypal do
        resource :hook do
          # TODO: verify signature
          post do
            case param("event_type") do
              "PAYMENT.SALE." <> event ->
                id    = param("resource")["parent_payment"]
                order = Repo.one!(Order.paypal(id)) |> Repo.preload([:event, purchases: :ticket])

                case event do
                  "COMPLETED" ->
                    Logger.info "PayPal payment completed for order #{order.id}", pay: :paypal
                    Repo.update!(order |> Order.update(%{ status: :paid }))

                    if mail = order.event.configuration.mail do
                      mail |> Event.Mail.new(order.email, order: order) |> Mailer.deliver_later
                    end

                  "DENIED" ->
                    Logger.info "PayPal payment denied for order #{order.id}", pay: :paypal
                    Repo.delete!(order)

                  "PENDING" ->
                    Logger.info "PayPal payment pending for order #{order.id}", pay: :paypal
                    Repo.update!(order |> Order.update(%{ status: :pending }))

                  "REFUNDED" ->
                    Logger.info "PayPal payment refunded for order #{order.id}", pay: :paypal
                    Repo.update!(order |> Order.update(%{ status: :refunded }))

                  "REVERSED" ->
                    Logger.info "PayPal payment reversed for order #{order.id}", pay: :paypal
                    Repo.update!(order |> Order.update(%{ status: :refunded }))
                end

              event ->
                Logger.warn "PayPal unhandled event #{event}"
            end

            reply 204
          end
        end

        resource :done do
          get do
            payment = query("paymentId")
            payer   = query("PayerID")
            order   = Repo.one!(Order.paypal(payment))

            if order.status != :created do
              fail 401
            else
              case Pay.Paypal.Payment.execute(payment, payer) do
                # Execution successful.
                { :ok, %{ "state" => "approved" } = response } ->
                  Logger.info "PayPal payment executed for order #{order.id}", pay: :paypal
                  Repo.update!(order
                    |> Order.update(%{ status: :pending })
                    |> Order.payment(:paypal, response))

                  redirect String.replace(
                    Application.get_env(:titticket, Pay.Paypal)[:success],
                    ":order",
                    to_string(order.id))

                # Execution failed.
                { :ok, %{ "state" => "failed" } = response } ->
                  Logger.error "PayPal payment failed for order #{order.id} because #{response["failure_reason"]}", pay: :paypal
                  Repo.delete!(order)

                  redirect String.replace(
                    Application.get_env(:titticket, Pay.Paypal)[:failure],
                    ":order",
                    to_string(order.id))

                # Network error.
                { :error, reason } ->
                  Logger.error "PayPal network error for order #{order.id} (#{inspect(reason)})", pay: :paypal

                  redirect String.replace(
                    Application.get_env(:titticket, Pay.Paypal)[:success],
                    ":order",
                    to_string(order.id))

                # PayPal error.
                { :error, code, reason } ->
                  Logger.error "PayPal payment error for order #{order.id} (#{code} #{inspect(reason)})", pay: :paypal

                  redirect String.replace(
                    Application.get_env(:titticket, Pay.Paypal)[:success],
                    ":order",
                    to_string(order.id))
              end
            end
          end
        end

        resource :cancel do
          get do
            token = query("token")
            order = Repo.one!(Order.paypal(token: token))

            if order.status != :created do
              fail 401
            else
              Logger.info "PayPal payment cancelled for order #{order.id}", pay: :paypal

              Repo.delete!(order)

              redirect String.replace(
                Application.get_env(:titticket, Pay.Paypal)[:cancel],
                ":order",
                to_string(order.id))
            end
          end
        end
      end
    end
  end
end

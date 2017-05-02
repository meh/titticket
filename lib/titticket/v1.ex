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

  alias Titticket.{Repo, Changeset, Status, Event, Ticket, Order, Purchase, Payment, Question, Answer, Pay}
  import Titticket.Authorization

  namespace :v1 do
    resource :event do
      # Get an event.
      get id, as: Integer do
        if event = Repo.get(Event, id) do
          tickets = Repo.all(Event.tickets(event))

          %{ opens:  event.opens,
             closes: event.closes,

             title:       event.title,
             description: event.description,
             status:      event.status,

             ticket: tickets }
        else
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
          with :authorized             <- can?({ :change, :event }),
               event when event != nil <- Repo.get(Event, id),
               { :ok, event }          <- Repo.update(event |> Event.change(params()))
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
          with :authorized             <- can?({ :delete, :event }),
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
        prepare = fn questions ->
          Question.unflatten questions, fn %Question{ id: id, amount: amount } = question ->
            case Question.dump(question) do
              { :ok, question } ->
                purchased = if amount do
                  Repo.one(Question.purchases(id))
                end

                { :ok, question |> Map.put("purchased", purchased) }

              :error ->
                :error
            end
          end
        end

        with ticket when ticket != nil <- Repo.get(Ticket, id) |> Repo.preload(:event),
             { :ok, status }           <- Ecto.Type.dump(Status, ticket.status),
             { :ok, payment }          <- Ecto.Type.dump({ :array, Payment }, ticket.payment),
             { :ok, questions }        <- prepare.(ticket.questions)
        do
          purchased = Repo.one(Ticket.purchases(ticket))

          %{ opens:  ticket.opens || ticket.event.opens,
             closes: ticket.closes || ticket.event.closes,

             title:       ticket.title,
             description: ticket.description,
             status:      status,

             amount:    %{purchased: purchased, max: ticket.amount},
             payment:   payment,
             questions: questions }
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
          with :authorized               <- can?({ :change, :event }),
               ticket when ticket != nil <- Repo.get(Ticket, id),
               0                         <- Ticket.purchases(ticket),
               { :ok, ticket }           <- Repo.update(ticket |> Ticket.change(params()))
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
          with :authorized               <- can?({ :delete, :ticket }),
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
      #
      # Answers to purchases are filtered out when set to private.
      get id do
        if order = Repo.get(Order, id) |> Repo.preload(purchases: [:ticket, :order]) do
          %{ event:     order.event_id,
             total:     Order.total(order),
             confirmed: order.confirmed,

             purchases: Enum.map(order.purchases, fn purchase ->
               %{ ticket:     purchase.ticket_id,
                  identifier: purchase.identifier,
                  total:      Purchase.total(purchase),
                  answers:    if(:authorized == can?({ :read, :answers }), do: purchase.answers, else: %{}) }
             end) }
        else
          fail 404
        end
      end
    end

    resource :purchase do
      post do
        Repo.transaction! fn ->
          available = fn purchase ->
            { :ok, purchase }
          end

          purchases = fn payment, event, order, tickets ->
            try do
              purchases = Enum.map tickets, fn current ->
                with ticket when ticket != nil <- Repo.get(Ticket, current["id"]),
                     :ok                       <- if(Enum.find(ticket.payment, &(&1.type == payment)), do: :ok, else: :no_payment),
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

          with :authorized             <- can?({ :buy, :ticket }),
               event when event != nil <- Repo.get(Event, param("event")),
               :active                 <- event.status,
               { :ok, order }          <- Repo.insert(Order.create(event)),
               { :ok, payment }        <- Payment.Type.cast(param("payment")["type"]),
               { :ok, _ }              <- purchases.(payment, event, order, param("tickets"))
          do
            { action, details } = case payment do
              :paypal ->
                response = Pay.Paypal.create!(order |> Repo.preload([:event, purchases: :ticket]))

                { %{ redirect: Enum.find(response["links"], &(&1["rel"] == "approval_url"))["href"] },
                  %{ id:       response["id"] } }

              _ ->
                { nil, %{} }
            end

            Repo.update!(order
              |> Order.payment(%Payment.Details{ type: payment, details: details }))

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
    end

    # PayPal redirection stuff.
    namespace :paypal do
      resource :done do
        get do
          payment  = query("paymentId")
          payer    = query("PayerID")
          response = Pay.Paypal.execute!(payment, payer)
          order    = Repo.one(Order.for_paypal(payment))

          Logger.info "PayPal payment executed for order #{order.id}"

          Repo.update!(order
            |> Order.confirm
            |> Order.payment(%{ order.payment | details: %{
              id:    payment,
              cert:  response["cert"],
              payer: payer } }))

          order.id
        end
      end

      resource :cancel do
        get do
          payment = query("paymentId")
          order   = Repo.one(Order.for_paypal(payment))

          Logger.info "PayPal payment cancelled for order #{order.id}"

          Repo.delete!(order)

          order.id
        end
      end
    end
  end
end

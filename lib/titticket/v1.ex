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

  import Ecto.Query

  alias Titticket.{Repo, Changeset, Status, Event, Ticket, Purchase, Payment, Question, Answer}
  import Titticket.Authorization

  namespace :v1 do
    resource :event do
      # Get an event.
      get id, as: Integer do
        if event = Repo.get(Event, id) do
          tickets = Repo.all(from t in Ticket,
            where:  t.event_id == ^event.id,
            select: t.id)

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
        with :authorized    <- can?({ :create, :event }),
             { :ok, event } <- Repo.insert(Event.create(params()))
        do
          event.id
        else
          :unauthorized ->
            fail 401

          { :error, changeset } ->
            fail Changeset.errors(changeset), 422
        end
      end

      # Delete an event.
      delete id, as: Integer do
        with :authorized             <- can?({ :delete, :event }),
             event when event != nil <- Repo.get(Event, id),
             { :ok, event }          <- Repo.delete(event)
        do
          event.id
        else
          :unauthorized ->
            fail 401

          { :error, changeset } ->
            fail Changeset.errors(changeset), 422

          nil ->
            fail 404
        end
      end
    end

    resource :ticket do
      # Get a ticket.
      get id, as: Integer do
        with ticket when ticket != nil <- Repo.get(Ticket, id) |> Repo.preload(:event),
             { :ok, status }           <- Ecto.Type.dump(Status, ticket.status),
             { :ok, payment }          <- Ecto.Type.dump({ :array, Payment }, ticket.payment),
             { :ok, questions }        <- Ecto.Type.dump({ :array, Question }, ticket.questions)
        do
          purchased = Repo.one(from p in Purchase,
            where:  p.ticket_id == ^ticket.id,
            select: count(p.id))

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
        with :authorized             <- can?({ :create, :ticket }),
             event when event != nil <- Repo.get(Event, param("event")),
             { :ok, ticket }         <- Repo.insert(IO.inspect(Ticket.create(event, params())))
        do
          ticket.id
        else
          :unauthorized ->
            fail 401

          { :error, changeset } ->
            fail Changeset.errors(changeset), 422

          nil ->
            fail 404
        end
      end

      # Delete a ticket.
      delete id, as: Integer do
        with :authorized               <- can?({ :delete, :ticket }),
             ticket when ticket != nil <- Repo.get(Ticket, id),
             { :ok, ticket }           <- Repo.delete(ticket)
        do
          ticket.id
        else
          :unauthorized ->
            fail 401

          { :error, changeset } ->
            fail Changeset.errors(changeset), 422

          nil ->
            fail 404
        end
      end
    end

    #    resource :purchase do
    #      post do
    #        valid = Enum.reduce param("tickets"), { :ok, [] }, fn
    #          current, { :ok, tickets } ->
    #            with ticket when ticket != nil <- Repo.get(Ticket, current["id"]),
    #                 { :ok, _ }                <- V.payment(current["payment"], ticket.payment),
    #                 { :ok, _ }                <- V.answers(current["answers"], ticket.questions)
    #            do
    #              { :ok, [current | tickets] }
    #            else
    #              error ->
    #                error
    #            end
    #        end
    #
    #        with :authorized      <- can?({ :buy, :ticket }),
    #             { :ok, tickets } <- valid
    #        do
    #          true
    #          #          Payment.create_payment(%Paypal.Payment{
    #          #            intent: "sale",
    #          #            payer:  %{"payment_method" => "paypal"},
    #          #  
    #          #            transactions: [%{
    #          #              "amount" => %{
    #          #                "currency" => Application.get_env(:titticket, :currency),
    #          #                "total"    => !price!,
    #        else
    #          :unauthorized ->
    #            fail 401
    #
    #          nil ->
    #            fail 404
    #        end
    #      end
    #    end
  end
end

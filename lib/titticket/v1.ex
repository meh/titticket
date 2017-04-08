defmodule Titticket.V1 do
  use Urna,
    allow:    [headers: true, methods: true, credentials: true],
    adapters: [Urna.JSON, Urna.Form]

  import Ecto.Query
  require Titticket.Validation

  alias Titticket.{Repo, Event, Ticket, Purchase}
  alias Titticket.Validation, as: V

  namespace :v1 do
    resource :event do
      get id, as: Integer do
        if event = Repo.get(Event, id) do
          tickets = Repo.all(from t in Ticket,
            where:  t.event_id == ^event.id,
            select: t.id)

          %{ opens:  event.opens,
             closes: event.closes,

             title:       event.title,
             description: event.description,
             state:       event.state,

             ticket: tickets }
        else
          fail 404
        end
      end

      post do
        with :authorized          <- V.can?({ :create, :event }),
             { :ok, opens }       <- V.date(param("opens")),
             { :ok, closes   }    <- V.date?(param("closes")),
             { :ok, title }       <- V.string(param("title")),
             { :ok, description } <- V.string?(param("description")),
             { :ok, state }       <- V.state(param("state"))
        do
          Repo.insert!(%Event{
            opens:  opens,
            closes: closes,

            title:       title,
            description: description,
            state:       state }).id
        else
          :unauthorized ->
            fail 401

          :error ->
            fail 422
        end
      end

      delete id, as: Integer do
        with :authorized             <- V.can?({ :delete, :event }),
             event when event != nil <- Repo.get(Event, id)
        do
          Repo.delete!(event).id
        else
          :unauthorized ->
            fail 401

          nil ->
            fail 404
        end
      end
    end

    resource :ticket do
      get id, as: Integer do
        if ticket = Repo.get(Ticket, id) |> Repo.preload(:event) do
          purchased = Repo.one(from p in Purchase,
            where:  p.ticket_id == ^ticket.id,
            select: count(p.id))

          %{ opens:  ticket.opens || ticket.event.opens,
             closes: ticket.closes || ticket.event.closes,

             title:       ticket.title,
             description: ticket.description,
             state:       ticket.state,

             amount:    %{purchased: purchased, max: ticket.amount},
             payment:   ticket.payment,
             questions: ticket.questions }
        else
          fail 404
        end
      end

      post do
        with :authorized             <- V.can?({ :create, :ticket }),
             { :ok, event }          <- V.integer(param("event")),
             event when event != nil <- Repo.get(Event, event),
             { :ok, opens }          <- V.date?(param("opens")),
             { :ok, closes   }       <- V.date?(param("closes")),
             { :ok, title }          <- V.string(param("title")),
             { :ok, description }    <- V.string?(param("description")),
             { :ok, state }          <- V.state(param("state")),
             { :ok, amount }         <- V.integer?(param("amount")),
             { :ok, payment }        <- V.payment(param("payment")),
             { :ok, questions }      <- V.questions(param("questions"))
        do
          Repo.insert!(%Ticket{
            opens:  opens,
            closes: closes,

            title:       title,
            description: description,
            state:       state,

            amount:    amount,
            payment:   payment,
            questions: questions,

            event: event }).id
        else
          :unauthorized ->
            fail 401

          :error ->
            fail 422

          nil ->
            fail 404
        end
      end
    end
  end
end

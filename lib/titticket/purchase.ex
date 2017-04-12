#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Purchase do
  use Ecto.Schema

  @primary_key { :id, :binary_id, autogenerate: true }
  schema "purchases" do
    timestamps()

    field :confirmed, :boolean, default: false

    field :identifier, :string
    field :private, :boolean, default: false

    field :type, Titticket.Payment.Type
    field :details, :map
    field :questions, { :array, Titticket.Question }
    field :answers, { :array, Titticket.Answer }

    belongs_to :ticket, Titticket.Ticket
  end
end

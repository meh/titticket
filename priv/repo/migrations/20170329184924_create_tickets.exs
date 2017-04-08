defmodule Titticket.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :opens, :date
      add :closes, :date

      add :title, :string
      add :description, :string
      add :state, :integer

      add :amount, :integer
      add :payment, { :array, :map }
      add :questions, { :array, :map }

      add :event_id, references(:events)
    end
  end
end

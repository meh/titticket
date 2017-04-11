defmodule Titticket.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      timestamps

      add :opens, :date
      add :closes, :date

      add :title, :string
      add :description, :string
      add :status, :integer

      add :amount, :integer
      add :payment, { :array, :map }
      add :questions, { :array, :map }

      add :event_id, references(:events)
    end
  end
end

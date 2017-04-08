defmodule Titticket.Repo.Migrations.CreateReservations do
  use Ecto.Migration

  def change do
    create table(:reservations) do
      add :at, :utc_datetime

      add :type, :integer
      add :details, :map
      add :answers, { :array, :map}

      add :ticket_id, references(:tickets)
    end
  end
end

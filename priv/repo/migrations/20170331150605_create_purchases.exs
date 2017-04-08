defmodule Titticket.Repo.Migrations.CreatePurchases do
  use Ecto.Migration

  def change do
    create table(:purchases) do
      add :at, :utc_datetime

      add :type, :integer
      add :details, :map
      add :answers, { :array, :map}

      add :ticket_id, references(:tickets)
    end
  end
end

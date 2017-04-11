defmodule Titticket.Repo.Migrations.CreatePurchases do
  use Ecto.Migration

  def change do
    create table(:purchases, primary_key: false) do
      timestamps

      add :id, :uuid, primary_key: true
      add :at, :utc_datetime
      add :confirmed, :boolean

      add :identifier, :string
      add :private, :boolean

      add :type, :integer
      add :details, :map
      add :questions, { :array, :map}
      add :answers, { :array, :map}

      add :ticket_id, references(:tickets)
    end
  end
end

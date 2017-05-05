defmodule Titticket.Repo.Migrations.CreatePurchases do
  use Ecto.Migration

  def change do
    create table(:purchases, primary_key: false) do
      timestamps()

      add :id, :uuid, primary_key: true
      add :answers, { :map, :map }

      add :ticket_id, references(:tickets)
      add :order_id, references(:orders, type: :uuid, on_delete: :delete_all)
    end
  end
end

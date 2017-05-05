defmodule Titticket.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      timestamps()

      add :id, :uuid, primary_key: true

      add :identifier, :string
      add :email, :string
      add :private, :boolean
      add :confirmed, :boolean

      add :payment, :map
      add :answers, { :map, :map }

      add :event_id, references(:events)
    end
  end
end

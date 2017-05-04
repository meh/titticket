defmodule Titticket.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      timestamps()

      add :opens, :date
      add :closes, :date

      add :title, :string
      add :description, :text
      add :status, :integer

      add :questions, { :map, :map }
    end
  end
end


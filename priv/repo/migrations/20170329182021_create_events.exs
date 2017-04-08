defmodule Titticket.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :opens, :date
      add :closes, :date

      add :title, :string
      add :description, :string
      add :state, :integer
    end
  end
end


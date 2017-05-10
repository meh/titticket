defmodule Titticket.Repo.Migrations.AddEventLinks do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :links, { :array, :map }
    end
  end
end

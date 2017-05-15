defmodule Titticket.Repo.Migrations.AddEventMail do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :mail, :map
    end
  end
end

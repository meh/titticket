defmodule Titticket.Repo.Migrations.ChangeOrderConfirmedToStatus do
  use Ecto.Migration
  import Ecto.Query

  def up do
    alter table(:orders) do
      add :status, :integer
    end

    flush

    Titticket.Repo.update_all from(o in "orders",
      update: [set: [status: 3]],
      where: o.confirmed), []

    Titticket.Repo.update_all from(o in "orders",
      update: [set: [status: 1]],
      where: not o.confirmed), []

    alter table(:orders) do
      remove :confirmed
    end
  end

  def down do
    alter table(:orders) do
      add :confirmed, :boolean
    end

    flush

    Titticket.Repo.update_all from(o in "orders",
      update: [set: [confirmed: true]],
      where: o.status == 3), []

    Titticket.Repo.update_all from(o in "orders",
      update: [set: [confirmed: false]],
      where: o.status != 3), []

    alter table(:orders) do
      remove :status
    end
  end
end

defmodule Titticket.Repo.Migrations.AddOrderIndices do
  use Ecto.Migration

  def up do
    execute "CREATE INDEX orders_payment_index ON orders USING gin (payment jsonb_path_ops)"
  end

  def down do
    execute "DROP INDEX orders_payment_index"
  end
end

defmodule Titticket.Repo.Migrations.AddEventConfiguration do
  use Ecto.Migration
  import Ecto.Query

  def up do
    alter table(:events) do
      add :configuration, :map
    end

    flush

    Enum.each Titticket.Repo.all(from e in "events", select: [e.id, e.links, e.mail]), fn [id, links, mail] ->
      Titticket.Repo.update_all from(e in "events",
        update: [set: [configuration: ^%{ links: links, mail: mail }]],
        where:  e.id == ^id), []
    end

    alter table(:events) do
      remove :links
      remove :mail
    end
  end

  def down do
    alter table(:events) do
      add :links, { :array, :map }
      add :mail, :map
    end

    flush

    Titticket.Repo.update_all from(e in "events",
      update: [set: [
        links: fragment("? #> 'links'", e.configuration),
        mail:  fragment("? #> 'mail'", e.configuration)]]), []

    alter table(:events) do
      remove :configuration
    end
  end
end

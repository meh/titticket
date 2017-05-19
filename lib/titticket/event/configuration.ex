#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Event.Configuration do
  alias __MODULE__
  alias Titticket.Event.{Link, Mail}

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    links:  { :array, Link },
    mail:   Mail,
  }

  defstruct links: [],
            mail:  nil

  def cast(params) when is_map(params) do
    { %Configuration{}, @types }
    |> cast(params, Map.keys(@types))
    |> cast_changes
  end

  def cast(_), do: :error

  def load(%{} = this) do
    with { :ok, links } <- Ecto.Type.load({ :array, Link }, this["links"] || []),
         { :ok, mail }  <- Ecto.Type.load(Mail, this["mail"])
    do
      { :ok, %Configuration{links: links, mail: mail} }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Configuration{links: links, mail: mail}) do
    with { :ok, links } <- Ecto.Type.dump({ :array, Link }, links),
         { :ok, mail }  <- Ecto.Type.dump(Mail, mail)
    do
      { :ok, %{ "links" => links, "mail" => mail } }
    else
      :error ->
        :error
    end
  end
end

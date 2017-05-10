#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Event.Link do
  alias __MODULE__

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    text: :string,
    href: :string,
  }

  defstruct text: nil,
            href: nil

  def cast(params) when is_map(params) do
    { %Link{}, @types }
    |> cast(params, Map.keys(@types))
    |> validate_required([:text, :href])
    |> cast_changes
  end

  def cast(_), do: :error

  def load(%{ "text" => text, "href" => href }) do
    { :ok, %Link{ text: text, href: href } }
  end

  def load(_), do: :error

  def dump(%Link{ text: text, href: href }) do
    { :ok, %{ "text" => text, "href" => href } }
  end

  def dump(_), do: :error
end

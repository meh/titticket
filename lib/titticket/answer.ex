#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Answer do
  alias __MODULE__
  alias Titticket.Question

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    id:    Ecto.UUID,
    value: :any,
  }

  defstruct id:    nil,
            value: nil

  def cast(params) when is_map(params) do
    { %Answer{}, @types }
    |> cast(params, Map.keys(@types))
    |> validate_required([:id, :value])
    |> cast_changes
  end

  def cast(_), do: :error

  def load(%{ "id" => id, "value" => value }) do
    with { :ok, id } <- Ecto.UUID.cast(id) do
      { :ok, %Answer{ id: id, value: value } }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Answer{ id: id, value: value }) do
    with { :ok, id } <- Ecto.Type.dump(:string, id) do
      { :ok, %{ "id" => id, "value" => value } }
    else
      :error ->
        :error
    end
  end

  def dump(_), do: :error

  def public(answer, question) do
    answer
  end
end

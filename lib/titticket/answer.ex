#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Answer do
  defstruct [:type]
  alias __MODULE__
  alias Titticket.Question

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    type: Question.Type,
  }

  def cast(params) do
    { %Answer{}, @types }
    |> cast(params, Map.keys(@types))
    |> validate_required([:type])
    |> cast_changes
  end

  def cast(_), do: :error

  def load(%{ "type" => type }) do
    with { :ok, type } <- Question.Type.load(type) do
      { :ok, %Answer{ type: type } }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Answer{ type: type }) do
    with { :ok, type } <- Question.Type.dump(type) do
      { :ok, %{ type: type } }
    else
      :error ->
        :error
    end
  end

  def dump(_), do: :error
end

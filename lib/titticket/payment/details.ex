#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Payment.Details do
  alias __MODULE__
  alias Titticket.Payment

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    type:    Payment.Type,
    details: :map,
  }

  defstruct type:    nil,
            details: %{}

  def cast(params) when is_map(params) do
    { %Details{}, @types }
    |> cast(params, Map.keys(@types))
    |> validate_required([:type])
    |> cast_changes
  end

  def cast(_), do: :error

  def load(%{ "type" => type, "details" => details }) do
    with { :ok, type }    <- Payment.Type.load(type),
         { :ok, details } <- Ecto.Type.load(:map, details)
    do
      { :ok, %Details{ type: type, details: details } }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Details{ type: type, details: details }) do
    with { :ok, type }    <- Payment.Type.dump(type),
         { :ok, details } <- Ecto.Type.dump(:map, details)
    do
      { :ok, %{ "type" => type, "details" => details } }
    else
      :error ->
        :error
    end
  end

  def dump(_), do: :error
end

#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Payment.Price.Beyond do
  alias __MODULE__

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    date:  :date,
    value: :decimal,
  }

  defstruct date:  nil,
            value: nil

  def cast(params) do
    { %Beyond{}, @types }
    |> cast(params, Map.keys(@types))
    |> validate_required([:date, :value])
    |> cast_changes
  end

  def load(%{ "date" => date, "value" => value }) do
    with { :ok, date }  <- Ecto.Type.cast(:date, date),
         { :ok, value } <- Ecto.Type.cast(:decimal, value)
    do
      { :ok, %Beyond{ date: date, value: value } }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Beyond{ date: date, value: value }) do
    with { :ok, date }  <- { :ok, Date.to_string(date) },
         { :ok, value } <- Ecto.Type.dump(:decimal, value)
    do
      { :ok, %{ "date" => date, "value" => value } }
    else
      :error ->
        :error
    end
  end

  def dump(_), do: :error
end

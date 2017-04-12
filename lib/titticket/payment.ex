#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Payment do
  defstruct [:type, :price]
  alias __MODULE__

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    type:  Payment.Type,
    price: Payment.Price,
  }

  def cast(params) do
    { %Payment{}, @types }
    |> cast(params, Map.keys(@types))
    |> validate_required([:type, :price])
    |> cast_changes
  end

  def cast(_), do: :error

  def load(%{ "type" => type, "price" => price }) do
    with { :ok, type }  <- Payment.Type.load(type),
         { :ok, price } <- Payment.Price.load(price)
    do
      { :ok, %Payment{ type: type, price: price } }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Payment{ type: type, price: price }) do
    with { :ok, type }  <- Payment.Type.dump(type),
         { :ok, price } <- Payment.Price.dump(price)
    do
      { :ok, %{ type: type, price: price } }
    else
      :error ->
        :error
    end
  end

  def dump(_), do: :error
end

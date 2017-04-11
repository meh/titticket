defmodule Titticket.Payment do
  defstruct [:type, :price]
  alias __MODULE__

  @behaviour Ecto.Type
  def type, do: :map

  def cast(%{ "type" => type, "price" => price }) do
    with { :ok, type }  <- Payment.Type.cast(type),
         { :ok, price } <- Payment.Price.cast(price)
    do
      { :ok, %Payment{ type: type, price: price } }
    else
      :error ->
        :error
    end
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

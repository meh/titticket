defmodule Titticket.Payment.Price do
  defstruct [:default, :beyond]
  alias __MODULE__

  @behaviour Ecto.Type
  def type, do: :map

  def cast(%{ "default" => default, "beyond" => beyond }) do
    with { :ok, default }      <- Ecto.Type.cast(:float, default),
         { :ok, beyond_date }  <- Ecto.Type.cast(:date, Enum.at(List.wrap(beyond), 0)),
         { :ok, beyond_price } <- Ecto.Type.cast(:float, Enum.at(List.wrap(beyond), 1))
    do
      { :ok, %Price{ default: default,
                     beyond: if(beyond, do: [beyond_date, beyond_price], else: nil) } }
    else
      :error ->
        :error
    end
  end

  def load(%{ "default" => default, "beyond" => beyond }) do
    with { :ok, default }      <- Ecto.Type.load(:float, default),
         { :ok, beyond_date }  <- Ecto.Type.load(:date, Enum.at(List.wrap(beyond), 0)),
         { :ok, beyond_price } <- Ecto.Type.load(:float, Enum.at(List.wrap(beyond), 1))
    do
      { :ok, %Price{ default: default,
                     beyond: if(beyond, do: [beyond_date, beyond_price], else: nil) } }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Price{ default: default, beyond: beyond }) do
    { :ok, %{ default: default, beyond: beyond } }
  end

  def dump(_), do: :error
end

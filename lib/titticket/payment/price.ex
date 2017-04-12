defmodule Titticket.Payment.Price do
  defstruct [:value, :beyond]
  alias __MODULE__

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    value:  :float,
    beyond: Price.Beyond,
  }

  def cast(params) do
    { %Price{}, @types }
    |> cast(params, Map.keys(@types))
    |> validate_required([:value])
    |> cast_changes
  end

  def load(%{ "value" => value, "beyond" => beyond }) do
    with { :ok, value }  <- Ecto.Type.load(:float, value),
         { :ok, beyond } <- Price.Beyond.load(beyond)
    do
      { :ok, %Price{ value: value, beyond: beyond } }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Price{ value: value, beyond: beyond }) do
    with { :ok, value }  <- Ecto.Type.dump(:float, value),
         { :ok, beyond } <- if(beyond, do: Price.Beyond.dump(beyond), else: { :ok, nil })
    do
      { :ok, %{ "value" => value, "beyond" => beyond } }
    else
      :error ->
        :error
    end
  end

  def dump(_), do: :error
end

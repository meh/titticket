defmodule Titticket.Payment.Price do
  alias __MODULE__

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    value:  :decimal,
    beyond: Price.Beyond,
  }

  defstruct value:  nil,
            beyond: nil

  def cast(params) do
    { %Price{}, @types }
    |> cast(params, Map.keys(@types))
    |> validate_required([:value])
    |> cast_changes
  end

  def load(%{ "value" => value, "beyond" => beyond }) do
    with { :ok, value }  <- Ecto.Type.cast(:decimal, value),
         { :ok, beyond } <- if(beyond, do: Price.Beyond.load(beyond), else: { :ok, nil })
    do
      { :ok, %Price{ value: value, beyond: beyond } }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Price{ value: value, beyond: beyond }) do
    with { :ok, value }  <- Ecto.Type.dump(:decimal, value),
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

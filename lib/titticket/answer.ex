defmodule Titticket.Answer do
  defstruct [:type]

  alias __MODULE__
  alias Titticket.Question

  @behaviour Ecto.Type
  def type, do: :map

  def cast(%{ "type" => type }) do
    with { :ok, type } <- Question.Type.cast(type) do
      { :ok, %Answer{ type: type } }
    else
      :error ->
        :error
    end
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

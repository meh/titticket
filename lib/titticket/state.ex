defmodule Titticket.State do
  @behaviour Ecto.Type
  def type, do: :integer

  def cast(:inactive),  do: { :ok, 0 }
  def cast(:active),    do: { :ok, 1 }
  def cast(:suspended), do: { :ok, 2 }
  def cast(_),          do: :error

  def load(0), do: { :ok, :inactive }
  def load(1), do: { :ok, :active }
  def load(2), do: { :ok, :suspended }
  def load(_), do: :error

  def dump(:inactive),  do: { :ok, 0 }
  def dump(:active),    do: { :ok, 1 }
  def dump(:suspended), do: { :ok, 2 }
  def dump(_),          do: :error
end

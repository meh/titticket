defmodule Titticket.Status do
  @behaviour Ecto.Type
  def type, do: :integer

  def cast(:inactive),   do: { :ok, :inactive }
  def cast("inactive"),  do: { :ok, :inactive }
  def cast(:active),     do: { :ok, :active }
  def cast("active"),    do: { :ok, :active }
  def cast(:suspended),  do: { :ok, :suspended }
  def cast("suspended"), do: { :ok, :suspended }
  def cast(_),           do: :error

  def load(0), do: { :ok, :inactive }
  def load(1), do: { :ok, :active }
  def load(2), do: { :ok, :suspended }
  def load(_), do: :error

  def dump(:inactive),  do: { :ok, 0 }
  def dump(:active),    do: { :ok, 1 }
  def dump(:suspended), do: { :ok, 2 }
  def dump(_),          do: :error
end

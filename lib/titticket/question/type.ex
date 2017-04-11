defmodule Titticket.Question.Type do
  @behaviour Ecto.Type
  def type, do: :string

  def cast(:text),  do: { :ok, :text }
  def cast("text"), do: { :ok, :text }
  def cast(:one),   do: { :ok, :one }
  def cast("one"),  do: { :ok, :one }
  def cast(:many),  do: { :ok, :many }
  def cast("many"), do: { :ok, :many }
  def cast(_),      do: :error

  def load("text"), do: { :ok, :text }
  def load("one"),  do: { :ok, :one }
  def load("many"), do: { :ok, :many }
  def load(_),      do: :error

  def dump(:text), do: { :ok, "text" }
  def dump(:one),  do: { :ok, "one" }
  def dump(:many), do: { :ok, "many" }
  def dump(_),     do: :error
end

defmodule Titticket.Payment.Type do
  @behaviour Ecto.Type
  def type, do: :integer

  def cast(:cash),    do: { :ok, :cash }
  def cast("cash"),   do: { :ok, :cash }
  def cast(:wire),    do: { :ok, :wire }
  def cast("wire"),   do: { :ok, :wire }
  def cast(:paypal),  do: { :ok, :paypal }
  def cast("paypal"), do: { :ok, :paypal }
  def cast(_),        do: :error

  def load(0), do: { :ok, :cash }
  def load(1), do: { :ok, :wire }
  def load(2), do: { :ok, :paypal }
  def load(_), do: :error

  def dump(:cash),   do: { :ok, 0 }
  def dump(:wire),   do: { :ok, 1 }
  def dump(:paypal), do: { :ok, 2 }
  def dump(_),       do: :error
end

#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Payment.Type do
  @behaviour Ecto.Type
  def type, do: :string

  def cast(:cash),  do: { :ok, :cash }
  def cast("cash"), do: { :ok, :cash }
  def cast(:wire),   do: { :ok, :wire }
  def cast("wire"),  do: { :ok, :wire }
  def cast(:paypal),  do: { :ok, :paypal }
  def cast("paypal"), do: { :ok, :paypal }
  def cast(_),      do: :error

  def load("cash"), do: { :ok, :cash }
  def load("wire"),  do: { :ok, :wire }
  def load("paypal"), do: { :ok, :paypal }
  def load(_),      do: :error

  def dump(:cash), do: { :ok, "cash" }
  def dump(:wire),  do: { :ok, "wire" }
  def dump(:paypal), do: { :ok, "paypal" }
  def dump(_),     do: :error
end

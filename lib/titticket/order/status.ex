#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Order.Status do
  @behaviour Ecto.Type
  def type, do: :integer

  def cast(:created),   do: { :ok, :created }
  def cast("created"),  do: { :ok, :created }
  def cast(:pending),   do: { :ok, :pending }
  def cast("pending"),  do: { :ok, :pending }
  def cast(:refunded),  do: { :ok, :refunded }
  def cast("refunded"), do: { :ok, :refunded }
  def cast(:paid),      do: { :ok, :paid }
  def cast("paid"),     do: { :ok, :paid }
  def cast(_),          do: :error

  def load(0), do: { :ok, :created }
  def load(1), do: { :ok, :pending }
  def load(2), do: { :ok, :refunded }
  def load(3), do: { :ok, :paid }
  def load(_), do: :error

  def dump(:created),  do: { :ok, 0 }
  def dump(:pending),  do: { :ok, 1 }
  def dump(:refunded), do: { :ok, 2 }
  def dump(:paid),     do: { :ok, 3 }
  def dump(_),         do: :error
end

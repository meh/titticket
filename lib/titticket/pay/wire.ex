#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Pay.Wire do
  alias Titticket.{Repo, Order}

  defp char(byte) when (byte >= ?0 and byte <= ?9) or (byte >= ?A and byte <= ?Z) do
    byte
  end

  defp char(_) do
    char(:crypto.rand_uniform(?0, ?Z))
  end

  @doc """
  Generate an ID.
  """
  def generate do
    Enum.map((0 .. 5), &char(&1)) |> to_string
  end

  @doc """
  Generate a unique ID.
  """
  # XXX: Halting problem much.
  def unique(id \\ generate) do
    if Repo.one(Order.wire(id)) do
      unique
    else
      id
    end
  end
end

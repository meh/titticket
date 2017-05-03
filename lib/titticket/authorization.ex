#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Authorization do
  defmacro can?(what) do
    quote do
      if header("X-Access-Token") == Application.get_env(:titticket, :secret) do
        unquote(__MODULE__).can?(:god, unquote(what))
      else
        unquote(__MODULE__).can?(nil, unquote(what))
      end
    end
  end

  # Administrator privileges, all of them!
  def can?(:god, _what), do: :authorized

  # Normal user privileges.
  def can?(_, { :see, :event, _ }),           do: :authorized
  def can?(_, { :see, :event, _, :tickets }), do: :authorized
  def can?(_, { :see, :ticket, _ }),          do: :authorized
  def can?(_, { :create, :order, _ }),        do: :authorized
  def can?(_, _),                             do: :unauthorized
end

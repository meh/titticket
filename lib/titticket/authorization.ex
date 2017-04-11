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

  def can?(:god, _what),              do: :authorized
  def can?(_user, { :buy, :ticket }), do: :authorized
  def can?(_user, _what),             do: :unauthorized
end

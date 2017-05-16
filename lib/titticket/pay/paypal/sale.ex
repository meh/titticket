defmodule Titticket.Pay.Paypal.Sale do
  use HTTProt
  import Titticket.Pay.Paypal.Agent

  @doc """
  Get the status of a sale.
  """
  def status(id) do
    HTTP.get("#{url}/payments/sale/#{id}", headers) |> parse
  end

  def status!(id) do
    status(id) |> bang
  end
end

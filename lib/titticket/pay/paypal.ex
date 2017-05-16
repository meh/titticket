defmodule Titticket.Pay.Paypal do
  alias __MODULE__
  alias Titticket.V1

  def start_link do
    # Start the agent.
    with { :ok, pid } <- Paypal.Agent.start_link,
         { :ok, id }  <- hooks()
    do
      { :ok, pid }
    else
      { :error, reason } ->
        { :error, reason }

      { :error, code, response } ->
        { :error, code, response }
    end
  end

  @events [
    "PAYMENT.SALE.COMPLETED",
    "PAYMENT.SALE.DENIED",
    "PAYMENT.SALE.PENDING",
    "PAYMENT.SALE.REFUNDED",
    "PAYMENT.SALE.REVERSED" ]

  @doc """
  Start the web hooks.
  """
  def hooks do
    with { :ok, list } <- Paypal.Hook.list,
         { :ok, id }   <- if_needed(list["webhooks"])
    do
      { :ok, id }
    else
      { :error, reason } ->
        { :error, reason }

      { :error, code, response } ->
        { :error, code, response }
    end
  end

  defp url do
    "#{Application.get_env(:titticket, V1)[:base]}/v1/paypal/hook"
  end

  defp if_needed(hooks) when is_list(hooks) do
    if_needed(hooks |> Enum.find(&(&1["url"] == url)))
  end

  defp if_needed(nil) do
    if_needed(nil, true)
  end

  defp if_needed(hook) do
    if_needed(hook, Enum.sort(@events) !=
      Enum.sort(Enum.map(hook["event_types"], &(&1["name"]))))
  end

  defp if_needed(hook, false) do
    { :ok, hook["id"] }
  end

  defp if_needed(_, true) do
    Paypal.Hook.create(url, @events)
  end
end

defmodule Titticket.Pay.Paypal do
  use HTTProt
  import Logger
  alias __MODULE__

  @real "https://api.paypal.com/v1"
  @sandbox "https://api.sandbox.paypal.com/v1"

  defstruct token: nil

  def start_link do
    Agent.start_link fn -> %Paypal{} end, name: Paypal
  end

  def url do
    if Application.get_env(:titticket, :paypal)[:sandbox] do
      @sandbox
    else
      @real
    end
  end

  def token do
    if expired? do
      response = HTTP.post!("#{url}/oauth2/token", "grant_type=client_credentials",
        "Accept":        "application/json",
        "Content-Type":  "application/x-www-form-urlencoded",
        "Authorization": "Basic #{auth}") |> parse

      case response do
        { :ok, params } ->
          Agent.update(Paypal, fn value ->
            %Paypal{ value | token: %{
              value:   params["access_token"],
              expires: DateTime.to_unix(DateTime.utc_now) + params["expires_in"] } }
          end)

        { :error, code, body } ->
          Logger.error inspect({ code, body })
      end
    end

    Agent.get(Paypal, &(&1.token))
  end

  def expired? do
    case Agent.get(Paypal, &(&1.token)) do
      %{expires: expires} ->
        DateTime.to_unix(DateTime.utc_now) > expires

      _ ->
        true
    end
  end

  defp auth do
    user = Application.get_env(:titticket, :paypal)[:client_id]
    pass = Application.get_env(:titticket, :paypal)[:secret]

    :base64.encode("#{user}:#{pass}")
  end

  defp headers do
    [ "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer #{token.value}" ]
  end

  @doc """
  Request a new payment.
  """
  def create(price) do
    result = HTTP.post!("#{url}/payments/payment", Poison.encode!(%{
      intent: :sale,
      payer:  %{payment_method: :paypal},

      transactions: [%{
        amount: %{
          currency: Application.get_env(:titticket, :paypal)[:currency],
          total:    price } }],

      redirect_urls: %{
        return_url: "#{Application.get_env(:titticket, :api)}/paypal/done",
        cancel_url: "#{Application.get_env(:titticket, :api)}/paypal/cancel" }
    }), headers) |> parse
  end

  def create!(price) do
    create(price) |> bang
  end

  @doc """
  Get the status of a payment.
  """
  def status(id) do
    HTTP.get!("#{url}/payments/payment/#{id}", headers) |> parse
  end

  def status!(id) do
    status(id) |> bang
  end

  @doc """
  Finalize a payment.
  """
  def execute(id, payer) do
    HTTP.post!("#{url}/payments/payment/#{id}/execute",  Poison.encode!(%{
      payer_id: payer }), headers) |> parse
  end

  def execute!(id, payer) do
    execute(id, payer) |> bang
  end

  @doc """
  Parse a response into something usable.
  """
  defp parse(response) do
    body = Poison.decode!(HTTP.Response.body!(response))

    if response.status |> HTTP.Status.success? do
      { :ok, body }
    else
      { :error, response.status.code, body }
    end
  end

  @doc """
  Raise in case of error.
  """
  defp bang(value) do
    case value do
      { :ok, value } ->
        value

      { :error, code, reason } ->
        raise { code, reason }
    end
  end
end

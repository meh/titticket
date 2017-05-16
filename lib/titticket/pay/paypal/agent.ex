defmodule Titticket.Pay.Paypal.Agent do
  use HTTProt
  import Logger

  alias __MODULE__, as: T
  alias Titticket.Pay.Paypal

  @real "https://api.paypal.com/v1"
  @sandbox "https://api.sandbox.paypal.com/v1"

  defstruct token: nil

  def start_link do
    Agent.start_link fn -> %T{} end, name: T
  end

  def url do
    if Mix.env == :prod do
      @real
    else
      @sandbox
    end
  end

  def token do
    if expired? do
      response = HTTP.post("#{url}/oauth2/token", "grant_type=client_credentials",
        "Accept":        "application/json",
        "Content-Type":  "application/x-www-form-urlencoded",
        "Authorization": "Basic #{auth}") |> parse

      case response do
        { :ok, params } ->
          Agent.update(T, fn value ->
            %T{ value | token: %{
              value:   params["access_token"],
              expires: DateTime.to_unix(DateTime.utc_now) + params["expires_in"] } }
          end)

        { :error, code, body } ->
          Logger.error inspect({ code, body })
      end
    end

    Agent.get(T, &(&1.token))
  end

  def expired? do
    case Agent.get(T, &(&1.token)) do
      %{ expires: expires } ->
        DateTime.to_unix(DateTime.utc_now) > expires

      _ ->
        true
    end
  end

  def auth do
    { user, pass } = if Mix.env == :prod do
      { Application.get_env(:titticket, Paypal)[:id],
        Application.get_env(:titticket, Paypal)[:secret] }
    else
      { Application.get_env(:titticket, Paypal)[:sandbox][:id],
        Application.get_env(:titticket, Paypal)[:sandbox][:secret] }
    end

    :base64.encode("#{user}:#{pass}")
  end

  def headers do
    [ "Accept":        "application/json",
      "Content-Type":  "application/json",
      "Authorization": "Bearer #{token.value}" ]
  end

  @doc """
  Parse a response into something usable.
  """
  @spec parse({ :ok, term } | { :error, term }) :: :ok | { :ok, term } | { :error, term } | { :error, HTTP.Status.t, term }
  def parse({ :ok, response }) do
    body = case HTTP.Response.body!(response) do
      nil ->
        %{}

      body ->
        case Poison.decode(body) do
          { :ok, data } ->
            data

          { :error, _, _ } ->
            body
        end
    end

    if response.status |> HTTP.Status.success? do
      { :ok, body }
    else
      { :error, response.status, body }
    end
  end

  def parse({ :error, reason }) do
    { :error, reason }
  end

  @doc """
  Raise in case of error.
  """
  def bang(value) do
    case value do
      { :ok, value } ->
        value

      { :error, code, reason } ->
        raise { code, reason }
    end
  end
end

defmodule Titticket.Pay.Paypal.Hook do
  use HTTProt
  import Titticket.Pay.Paypal.Agent

  @doc """
  List all available web hooks.
  """
  def list do
    HTTP.get("#{url}/notifications/webhooks", headers) |> parse
  end

  @doc """
  Check if there are any web hooks present for the given URL.
  """
  def exists?(hook) do
    case list() do
      { :ok, response } ->
        matching = response["webhooks"]
          |> Enum.filter(&(&1["url"] == hook))
          |> Enum.map(&(&1["id"]))

        if Enum.empty?(matching) do
          { :ok, false }
        else
          { :ok, matching }
        end

      { :error, reason } ->
        { :error, reason }

      { :error, code, response } ->
        { :error, code, response }
    end
  end

  @doc """
  Create a new web hook for the given events.
  """
  def create(hook, events) do
    HTTP.post("#{url}/notifications/webhooks", Poison.encode!(%{
      url:         hook,
      event_types: Enum.map(events, &%{ name: &1 }) }), headers) |> parse
  end

  @doc """
  Delete the given web hook.
  """
  def delete(id) do
    HTTP.delete("#{url}/notifications/webhooks/#{id}", headers) |> parse
  end

  @doc """
  Clear all the present web hooks for the given URL.
  """
  def clear(hook) do
    case exists?(hook) do
      { :ok, false } ->
        { :ok, false }

      { :ok, list } ->
        Enum.reduce list, { :ok, [] }, fn
          id, { :ok, acc } ->
            case delete(id) do
              { :ok, _ } ->
                { :ok, [id | acc] }

              error ->
                error
            end

          _id, error ->
            error
        end

      { :error, reason } ->
        { :error, reason }

      { :error, code, response } ->
        { :error, code, response }
    end
  end
end

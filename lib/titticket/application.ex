defmodule Titticket.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Titticket.Repo, []),
      supervisor(Urna, [Titticket.V1, [port: Application.get_env(:titticket, :port)]]),
    ]

    opts = [strategy: :one_for_one, name: Titticket.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

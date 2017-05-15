#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Application do
  @moduledoc false

  use Application
  alias Titticket.{V1, Pay, Repo}

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Pay.Paypal, []),
      supervisor(Repo, []),
      supervisor(Urna, [V1, [
        host: Application.get_env(:titticket, V1)[:host],
        port: Application.get_env(:titticket, V1)[:port] ]]),
    ]

    opts = [strategy: :one_for_one, name: Titticket.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

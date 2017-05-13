defmodule Titticket.Mailer do
  use Bamboo.Mailer,
    otp_app: :titticket

  import Bamboo.Email
  alias Titticket.{Repo, Order}

  def order(order) do
    order(order, order.email, List.wrap(Application.get_env(:titticket, :mail)[:notify]))
  end

  def order(order, to, notify \\ []) do
    sender  = Application.get_env(:titticket, :mail)[:sender]
    subject = Application.get_env(:titticket, :mail)[:order][:subject]
    html    = Application.get_env(:titticket, :mail)[:order][:html]
    text    = Application.get_env(:titticket, :mail)[:order][:text]

    new_email
    |> from(sender)
    |> to(to)
    |> bcc(notify)
    |> subject(EEx.eval_string(subject, order: order))
    |> html_body(EEx.eval_string(html, order: order))
    |> text_body(EEx.eval_string(text, order: order))
  end
end

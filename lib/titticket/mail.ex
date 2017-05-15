#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Mail do
  alias __MODULE__

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    sender:  :string,
    notify:  { :array, :string },
    subject: :string,
    html:    :string,
    plain:   :string
  }

  defstruct sender:  nil,
            notify:  [],
            subject: nil,
            html:    nil,
            plain:   nil

  def cast(params) when is_map(params) do
    { %Mail{}, @types }
    |> cast(params, Map.keys(@types))
    |> validate_required([:sender, :subject, :html, :plain])
    |> cast_changes
  end

  def cast(_), do: :error

  def load(%{ "sender" => sender, "subject" => subject, "html" => html, "plain" => plain } = this) do
    with { :ok, sender }  <- Ecto.Type.load(:string, sender),
         { :ok, notify }  <- Ecto.Type.load({ :array, :string }, this["notify"] || []),
         { :ok, subject } <- Ecto.Type.load(:string, subject),
         { :ok, html }    <- Ecto.Type.load(:string, html),
         { :ok, plain }   <- Ecto.Type.load(:string, plain)
    do
      { :ok, %Mail{sender: sender, notify: notify, subject: subject, html: html, plain: plain} }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Mail{sender: sender, notify: notify, subject: subject, html: html, plain: plain}) do
    with { :ok, sender }  <- Ecto.Type.dump(:string, sender),
         { :ok, notify }  <- Ecto.Type.dump({ :array, :string }, notify),
         { :ok, subject } <- Ecto.Type.dump(:string, subject),
         { :ok, html }    <- Ecto.Type.dump(:string, html),
         { :ok, plain }   <- Ecto.Type.dump(:string, plain)
    do
      { :ok, %{ "sender" => sender, "notify" => notify, "subject" => subject, "html" => html, "plain" => plain } }
    else
      :error ->
        :error
    end
  end

  def new(this, to, fields \\ []) do
    import Bamboo.Email

    new_email
    |> from(this.sender)
    |> to(to)
    |> bcc(this.notify)
    |> subject(EEx.eval_string(this.subject, assigns: fields))
    |> html_body(EEx.eval_string(this.html, assigns: fields))
    |> text_body(EEx.eval_string(this.plain, assigns: fields))
  end
end

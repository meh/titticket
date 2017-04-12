#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Question do
  defstruct [:type, :required, :title]
  alias __MODULE__

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    type:     Question.Type,
    required: :boolean,
    title:    :string,
  }

  def cast(params) do
    { %Question{}, @types }
    |> cast(params, Map.keys(@types))
    |> validate_required([:type, :required, :title])
    |> cast_changes
  end

  def cast(_), do: :error

  def load(%{ "type" => type, "required" => required, title: title }) do
    with { :ok, type }     <- Question.Type.load(type),
         { :ok, required } <- Ecto.Type.load(:boolean, required),
         { :ok, title }    <- Ecto.Type.load(:string, title)
    do
      { :ok, %Question{ type: type,  required: required, title: title } }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Question{ type: type, required: required, title: title }) do
    with { :ok, type }     <- Question.Type.dump(type),
         { :ok, required } <- Ecto.Type.dump(:boolean, required),
         { :ok, title }    <- Ecto.Type.dump(:string, title)
    do
      { :ok, %{ type: type, required: required, title: title } }
    else
      :error ->
        :error
    end
  end
end

#    with { :ok, _ } <- question_type(value["type"]),
#         { :ok, _ } <- state(value["state"]),
#         { :ok, _ } <- bool(value["required"]),
#         { :ok, _ } <- string(value["title"]),
#         { :ok, _ } <- questions(value["children"])

defmodule Titticket.Question do
  defstruct [:type, :required?, :title]
  alias __MODULE__

  @behaviour Ecto.Type
  def type, do: :map

  def cast(%{ "type" => type, "required" => required?, "title" => title }) do
    with { :ok, type }      <- Question.Type.cast(type),
         { :ok, required? } <- Ecto.Type.cast(:boolean, required?),
         { :ok, title }     <- Ecto.Type.cast(:string, title)
    do
      { :ok, %Question{ type: type, required?: required?, title: title } }
    else
      :error ->
        :error
    end
  end

  def cast(_), do: :error

  def load(%{ "type" => type, "required" => required?, title: title }) do
    with { :ok, type }      <- Question.Type.load(type),
         { :ok, required? } <- Ecto.Type.load(:boolean, required?),
         { :ok, title }     <- Ecto.Type.load(:string, title)
    do
      { :ok, %Question{ type: type,  required?: required?, title: title } }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Question{ type: type, required?: required?, title: title }) do
    with { :ok, type } <- Question.Type.dump(type),
         { :ok, required? } <- Ecto.Type.dump(:boolean, required?),
         { :ok, title }     <- Ecto.Type.dump(:string, title)
    do
      { :ok, %{ type: type, required: required?, title: title } }
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

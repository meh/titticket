#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Changeset do
  defmacro __using__(_opts) do
    quote do
      import Ecto.Changeset
      import Titticket.Changeset
    end
  end

  import Ecto.Changeset
  alias Titticket.Payment

  def errors(changeset) do
    Enum.map(changeset.errors, fn
      { field, { message, values } } -> %{
        field: field,
        detail: Enum.reduce(values, message, fn { k, v }, acc ->
          String.replace(acc, "%{#{k}}", to_string(v))
        end) }

      { field, message } -> %{
        field: field,
        detail: message }
    end)
  end

  def cast_changes(changeset) do
    if changeset.valid? do
      { :ok, apply_changes(changeset) }
    else
      :error
    end
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end

  def validate_payment(changeset, choice, field, opts \\ []) do
    validate_change changeset, field, :payment, fn _, value ->
      []
    end
  end

  def validate_answers(changeset, questions, field, opts \\ []) do
    validate_change changeset, field, :answers, fn _, value ->
      []
    end
  end
end

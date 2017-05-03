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
  alias Titticket.{Payment, Question, Answer}

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end

  @doc """
  Convert changeset errors to something JSON encodable.
  """
  def errors(%Ecto.Changeset{} = changeset) do
    errors(changeset.errors)
  end

  def errors(errors) do
    Enum.map(errors, fn
      { field, { message, values } } -> %{
        field: field,
        detail: Enum.reduce(values, message, fn { k, v }, acc ->
          String.replace(acc, "%{#{k}}", inspect(v))
        end) }

      { field, message } -> %{
        field: field,
        detail: message }
    end)
  end

  @doc """
  Cast a set of questions.
  """
  def cast_questions(changeset, nil) do
    changeset
  end

  def cast_questions(changeset, questions) do
    case Question.flatten(questions) do
      { :ok, questions } ->
        changeset |> put_change(:questions, questions)

      :error ->
        changeset |> add_error(:questions, "is invalid")
    end
  end

  @doc """
  Cast a set of answers.
  """
  def cast_answers(changeset, nil) do
    changeset
  end

  def cast_answers(changeset, answers) do
    try do
      answers = Enum.map answers, fn answer ->
        case Answer.cast(answer) do
          { :ok, answer } ->
            { answer.id, answer }

          :error ->
            throw :error
        end
      end

      changeset |> put_change(:answers, answers |> Enum.into(%{}))
    catch
      :error ->
        changeset |> add_error(:answers, "is invalid")
    end
  end

  @doc """
  Transform a changeset to a castable.
  """
  def cast_changes(changeset) do
    if changeset.valid? do
      { :ok, apply_changes(changeset) }
    else
      :error
    end
  end

  @doc """
  Validate a payment based on the details given.

  TODO: actually validate the payment
  """
  def validate_payment(changeset, field, details, opts \\ []) do
    validate_change changeset, field, :payment, fn _, value ->
      []
    end
  end

  @doc """
  Validate a set of answers based on the question schema they should respect.

  TODO: actually validate the answers
  """
  def validate_answers(changeset, field, questions, opts \\ []) do
    validate_change changeset, field, :answers, fn _, answers ->
      if (answers == nil) != (questions == nil) do
        [{ field, { message(opts, "invalid answers"), [validation: :answers] } }]
      else
        Enum.flat_map answers, fn { id, answer } ->
          do_validate_answers(answer, questions[id], opts)
        end
      end
    end
  end

  defp do_validate_answers(answer, questions, opts \\ [])

  defp do_validate_answers(answer, nil, opts) do
    [{ :answers, { message(opts, "missing question"), [validation: :answers] } }]
  end

  defp do_validate_answers(answer, question, opts) do
    []
  end
end

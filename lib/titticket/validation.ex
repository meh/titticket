defmodule Titticket.Validation do
  defmacro can?(_what) do
    quote do
      if header("X-Access-Token") == Application.get_env(:titticket, :secret) do
        :authorized
      else
        :unauthorized
      end
    end
  end

  def state("inactive"),  do: { :ok, :inactive }
  def state("active"),    do: { :ok, :active }
  def state("suspended"), do: { :ok, :suspended }
  def state(_),           do: :error

  def question_type("text"), do: { :ok, :text }
  def question_type("one"),  do: { :ok, :one }
  def question_type("many"), do: { :ok, :many }
  def question_type(_),      do: :error

  def date(value) when value |> is_binary, do: Date.from_iso8601(value)
  def date(_),                             do: :error

  def date?(nil),   do: { :ok, nil }
  def date?(value), do: date(value)

  def string(value) when value |> is_binary, do: { :ok, value }
  def string(_),                             do: :error

  def string?(nil),   do: { :ok, nil }
  def string?(value), do: string(value)

  def bool(value) when value |> is_boolean, do: { :ok, value }
  def bool(_),                              do: :error

  def bool?(nil),   do: { :ok, nil }
  def bool?(value), do: bool(value)

  def number(value) when value |> is_number, do: { :ok, value }
  def number(_),                              do: :error

  def number?(nil),   do: { :ok, nil }
  def number?(value), do: number(value)

  def integer(value) when value |> is_integer, do: { :ok, value }
  def integer(_),                              do: :error

  def integer?(nil),   do: { :ok, nil }
  def integer?(value), do: integer(value)

  def list([]),                            do: :error
  def list(value) when not is_list(value), do: :error
  def list(value),                         do: { :ok, value }

  def list?(nil),   do: { :ok, nil }
  def list?([]),    do: { :ok, nil }
  def list?(value), do: list(value)

  def map(value) when value |> is_map, do: { :ok, value }
  def map(_),                          do: :error

  def map?(nil),   do: { :ok, nil }
  def map?(value), do: map(value)

  def either(list, value) do
    if Enum.member?(list, value) do
      { :ok, value }
    else
      :error
    end
  end

  def either?(_, nil),      do: { :ok, nil }
  def either?(list, value), do: either(list, value)

  @doc """
    type  - :cash | :wire | :paypal
    price - { default: float, after: [date, float] }
  """
  def payment([]),                                do: :error
  def payment(payment) when not is_list(payment), do: :error
  def payment(payment) do
    Enum.reduce payment, { :ok, [] }, fn
      _, :error ->
        :error

      current, { :ok, payment } ->
        with { :ok, _ }        <- either(["cash", "wire", "paypal"], current["type"]),
             { :ok, price }    <- map(current["price"]),
             { :ok, _ }        <- number(price["default"]),
             { :ok, increase } <- list?(price["after"]),
             { :ok, _ }        <- if(increase, do: number(increase |> Enum.at(0)), else: { :ok, nil }),
             { :ok, _ }        <- if(increase, do: date(increase |> Enum.at(1)), else: { :ok, nil })
        do
          { :ok, payment ++ [current] }
        else
          :error ->
            :error
        end
    end
  end

  def questions(nil),                                   do: { :ok, nil }
  def questions(questions) when not is_list(questions), do: :error
  def questions(questions) do
    Enum.reduce questions, { :ok, [] }, fn
      _, :error ->
        :error

      current, { :ok, questions } ->
        question(current)
    end
  end

  def question(value) when not is_map(value), do: :error

  def question(event = %{"type" => "text"}) do

  end

  def question(event = %{"type" => "one"}) do

  end

  def question(event = %{"type" => "many"}) do

  end

  def question(value) do
    with { :ok, _ } <- question_type(value["type"]),
         { :ok, _ } <- state(value["state"]),
         { :ok, _ } <- bool(value["required"]),
         { :ok, _ } <- string(value["title"]),
         { :ok, _ } <- questions(value["children"])
    do
      { :ok, value }
    else
      :error ->
        :error
    end
  end

  def answers(nil, nil),                                                               do: { :ok, nil }
  def answers(answers, questions) when not is_list(answers) or not is_list(questions), do: :error
  def answers(answers, questions) when length(answers) != length(questions),           do: :error
  def answers(answers, questions) do
    Enum.reduce Enum.zip(answers, questions), { :ok, [] }, fn
      _, :error ->
        :error

      { answer, question }, { :ok, answers } ->
        { :ok, answers ++ [answer] }
    end
  end
end

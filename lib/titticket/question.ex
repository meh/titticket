#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Titticket.Question do
  alias __MODULE__
  alias Titticket.Purchase

  @behaviour Ecto.Type
  def type, do: :map

  use Titticket.Changeset
  @types %{
    id:       Ecto.UUID,
    type:     Question.Type,
    required: :boolean,
    title:    :string,
    price:    :decimal,
    amount:   :integer,
    children: { :array, Ecto.UUID }
  }

  defstruct id:       nil,
            type:     nil,
            required: false,
            title:    nil,
            price:    nil,
            amount:   nil,
            children: []

  def cast(params) when is_map(params) do
    { %Question{}, @types }
    |> cast(params, Map.keys(@types))
    |> validate_required([:id, :type, :title])
    |> cast_changes
  end

  def cast(_), do: :error

  def load(%{ "id" => id, "type" => type, "required" => required, "title" => title, "price" => price, "amount" => amount, "children" => children }) do
    with { :ok, id }       <- Ecto.UUID.cast(id),
         { :ok, type }     <- Question.Type.load(type),
         { :ok, required } <- Ecto.Type.load(:boolean, required),
         { :ok, title }    <- Ecto.Type.load(:string, title),
         { :ok, price }    <- Ecto.Type.cast(:decimal, price),
         { :ok, amount }   <- Ecto.Type.load(:integer, amount),
         { :ok, children } <- Ecto.Type.cast({ :array, Ecto.UUID }, children)
    do
      { :ok, %Question{ id: id, type: type,  required: required, title: title, price: price, amount: amount, children: children } }
    else
      :error ->
        :error
    end
  end

  def load(_), do: :error

  def dump(%Question{ id: id, type: type, required: required, title: title, price: price, amount: amount, children: children }) do
    with { :ok, id }       <- Ecto.Type.dump(:string, id),
         { :ok, type }     <- Question.Type.dump(type),
         { :ok, required } <- Ecto.Type.dump(:boolean, required),
         { :ok, title }    <- Ecto.Type.dump(:string, title),
         { :ok, price }    <- Ecto.Type.dump(:decimal, price),
         { :ok, amount }   <- Ecto.Type.dump(:integer, amount),
         { :ok, children } <- Ecto.Type.dump({ :array, :string }, children)
    do
      { :ok, %{ "id" => id, "type" => type, "required" => required, "title" => title, "price" => price, "amount" => amount, "children" => children } }
    else
      :error ->
        :error
    end
  end

  def unflatten(questions, mapper \\ fn question -> Question.dump(question) end) do
    try do
      questions = Enum.map questions["00000000-0000-0000-0000-000000000000"].children, fn id ->
        do_unflatten(questions, id, mapper)
      end

      { :ok, questions }
    catch
      :error ->
        :error
    end
  end

  defp do_unflatten(questions, id, mapper) do
    case mapper.(questions[id]) do
      { :ok, mapped } ->
        mapped |> Map.update("children", [], fn children ->
          Enum.map(children, &do_unflatten(questions, &1, mapper))
        end)

      :error ->
        throw :error
    end
  end

  def flatten(questions, mapper \\ fn question -> Question.cast(question) end) do
    try do
      { roots, rest } = Enum.unzip(Enum.map(questions, fn question ->
        { question, rest } = do_flatten(question, mapper)
      end))

      questions = List.flatten([roots, rest])
      |> Enum.map(&{ &1.id, &1 })
      |> Enum.into(%{})
      |> Map.put("00000000-0000-0000-0000-000000000000", %Question{
        id: "00000000-0000-0000-0000-000000000000",
        type: :root,
        title: "",
        children: Enum.map(roots, &(&1.id)) })

      { :ok, questions }
    catch
      :error ->
        :error
    end
  end

  defp do_flatten(question, mapper) do
    { children, rest } = Enum.unzip(Enum.map(List.wrap(question["children"]), fn child ->
      do_flatten(child, mapper)
    end))

    question = question
      |> Map.put("id", Ecto.UUID.generate)
      |> Map.put("children", children |> Enum.map(&(&1.id)))

    case mapper.(question) do
      { :ok, mapped } ->
        { mapped, [children, rest] }

      :error ->
        throw :error
    end
  end

  def purchases(id) do
    import Ecto.Query

    from p in Purchase,
      where: fragment("? \\? ?", p.answers, ^id),
      select: count(p.id)
  end
end

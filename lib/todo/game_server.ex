defmodule Todo.GameServer do
  use GenServer

  # Client
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def first() do
    GenServer.call(__MODULE__, {:first})
  end

  def answer(question, history) do
    GenServer.call(__MODULE__, {:answer, {question, history}})
  end
  
  def check_previous(question, history) do
    GenServer.call(__MODULE__, {:check_previous, {question, history}})
  end

  # Server

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:first}, _from, state) when state != nil do
    word = Todo.Repository.select_words() |> Enum.random()
    {:reply, {[word], word}, state}
  end

  def handle_call({:answer, {question, history}}, _from, state) do
    answer =
      Todo.Repository.select_words()
      |> remove_used(history)
      |> find_answer(question)
      |> Enum.random()

    {:reply, {[answer]++[question]++history, answer}, state}
  end

  def handle_call({:check_previous, {question, history}}, _from, state) do
    correction = check_previous_aux(question, history)

    {:reply, correction, state}
  end

  def check_previous_aux(question, history) do
    previous_question = history |> Enum.at(0)
    previous_question_last_char = previous_question  |> String.at(String.length(previous_question) - 1)
    question_first_char = question |> String.at(0)
    case  previous_question_last_char == question_first_char do
      true -> "correct"
      false -> "invalid_response"
    end
  end

  defp remove_used(word_list, history) do
    word_list
    |> Enum.filter(fn word ->
      not (word in history)
    end)
  end

  # TODO arreglar bug: como hace comparacion directa no funciona bien con las tildes (purgar todas las tildes??)
  defp find_answer(word_list, question) do
    word_list
    |> Enum.filter(fn word ->
      question |> String.at(String.length(question) - 1) == word |> String.at(0)
    end)
  end
end

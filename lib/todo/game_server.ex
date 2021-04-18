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

  # Server

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:first}, _from, state) when state != nil do
    word = Todo.Repository.select_words() |> Enum.random()
    {:reply, {[], word}, state}
  end

  def handle_call({:answer, {question, history}}, _from, state) when state != nil do
    answer = Todo.Repository.select_words()
      |> remove_used(history)
      |> findAnswer(question)
    
    {:reply, {history++answer, answer}, state}
  end

  def remove_used(word_list, history) do
    word_list 
        |> Enum.filter(
          fn word -> 
            not(word in history)
          end
        )
  end

  defp findAnswer(_word_list, _question) do
  end
end

defmodule WordChain.GameServer do
  @moduledoc """
    Módulo encargado de gestionar las operaciones relacionadas con el juego.
  """
  use GenServer

  # ####################################### CLIENT #################################################
  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
    Obtiene aleatoriamente la primera palabra para comenzar a jugar.
  """
  def first() do
    GenServer.call(__MODULE__, {:first})
  end

  @doc """
    Devuelve una respuesta válida y única para la palabra actual.
    Para ello se basa en el historial de palabras ya usadas y comprueba que no se repita.
  """
  def answer(question, history) do
    GenServer.call(__MODULE__, {:answer, {question, history}})
  end

  @doc """
    Comprueba que la palabra actual sea válida para la respuesta anterior.
    Para ello comprueba si el último caracter de la pregunta coincide con el primero de la respuesta.
  """
  def check_previous(question, history) do
    GenServer.call(__MODULE__, {:check_previous, {question, history}})
  end

  # ####################################### SERVER #################################################

  @doc false
  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:first}, _from, state) when state != nil do
    word = WordChain.Repository.select_words() |> Enum.random()
    {:reply, {[word], word}, state}
  end

  def handle_call({:answer, {question, history}}, _from, state) do
    try do
      answer =
        WordChain.Repository.select_words_by_letter(question)
        |> remove_used(history)
        |> find_answer(question)
        |> Enum.random()
        {:reply, {[answer] ++ [sanitize_string(question)] ++ history, answer}, state} 
    rescue _e in Enum.EmptyError -> {:reply, {[], ""}, state} 
    end
    
  end

  def handle_call({:check_previous, {question, history}}, _from, state) do
    correction = check_previous_aux(question, history)

    {:reply, correction, state}
  end

  @doc false
  def check_previous_aux(question, history) do
    if validateQuestion(question) == false do
      "invalid_response"
    else
      sanitized_question = sanitize_string(question)
      IO.puts(sanitized_question)
      previous_question = history |> Enum.at(0)

      previous_question_last_char =
        previous_question |> String.at(String.length(previous_question) - 1)

      question_first_char = sanitized_question |> String.at(0)

      if sanitized_question in history do
        "already_used"
      else
        case previous_question_last_char == question_first_char do
          true -> "correct"
          false -> "invalid_response"
        end
      end
    end
  end

  def validateQuestion(question) do
    case HTTPoison.get("https://dle.rae.es/#{question}") do
      {:ok, response} ->
        if Map.fetch(response, :status_code) == {:ok, 301} do
          true
        else
          {:ok, html} = Map.fetch(response, :body)
          {:ok, document} = Floki.parse_document(html)

          resultado =
            Floki.find(document, "#resultados") |> List.first() |> elem(2) |> List.first()

          resultado != "Aviso: "
        end

      {_, _} ->
        false
    end
  end

  defp remove_used(word_list, history) do
    word_list
    |> Enum.filter(fn word ->
      not (word in history)
    end)
  end

  defp find_answer(word_list, question) do
    word_list
    |> Enum.filter(fn word ->
      question |> String.at(String.length(question) - 1) == word |> String.at(0)
    end)
  end

  defp sanitize_string(word) do
    word
    |> String.replace("%C3", "")
    |> String.replace("%A1", "a")
    |> String.replace("%A9", "e")
    |> String.replace("%AD", "i")
    |> String.replace("%B3", "o")
    |> String.replace("%BA", "u")
    |> String.replace("%B1", "ñ")
    |> String.replace("%81", "A")
    |> String.replace("%89", "E")
    |> String.replace("%8D", "I")
    |> String.replace("%93", "O")
    |> String.replace("%9A", "U")
    |> String.replace("%91", "Ñ")
  end
end

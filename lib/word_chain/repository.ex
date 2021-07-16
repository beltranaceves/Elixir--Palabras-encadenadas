defmodule WordChain.Repository do
  @moduledoc """
    Módulo encargado de gestionar las operaciones del repositorio mediante el patrón fachada.
  """
  use GenServer

  # ####################################### CLIENT #################################################
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
    Crea las tablas en la BD.
  """
  def create_tables() do
    GenServer.call(__MODULE__, {:create})
  end

  @doc """
    Borra las tablas en la BD.
  """
  def drop_tables() do
    GenServer.call(__MODULE__, {:drop})
  end

  @doc """
    Inserta el usuario recibido en la BD.
  """
  def insert_user(user) do
    GenServer.call(__MODULE__, {:insert, user})
  end

  @doc """
    Busca el usuario recibido en la BD.
  """
  def select_user(username) do
    GenServer.call(__MODULE__, {:select_user, username})
  end

  @doc """
    Selecciona una palabra en el fichero de palabras local.
  """
  def select_words_local() do
    GenServer.call(__MODULE__, {:select_words_local})
  end

  @doc """
    Selecciona una palabra de la BD.
  """
  def select_words() do
    GenServer.call(__MODULE__, {:select_words})
  end

  @doc """
    Selecciona una palabra de la BD que comience por el argumento recibido.
  """
  def select_words_by_letter(word) do
    GenServer.call(__MODULE__, {:select_words_by_letter, word})
  end

  @doc """
    Extrae las palabras del fichero local y las inserta en la BD.
  """
  def insert_words() do
    GenServer.call(__MODULE__, {:insert_words}, 500_000_000)
  end

  @doc """
    Ejecuta contra la BD al consulta recibida.
  """
  def query(query) do
    GenServer.call(__MODULE__, {:query, query})
  end

  # ####################################### SERVER #################################################
  @doc false
  def init(:ok) do
    {:ok, db_pid} =
      Postgrex.start_link(
        hostname: "postgres-free-tier-v2020.gigalixir.com",
        username: "cfb90dd3-5abc-4a77-baa0-5017b6d08537-user",
        password: "pw-43d07f2b-f743-4e03-a6d6-93c59485e75e",
        database: "cfb90dd3-5abc-4a77-baa0-5017b6d08537"
      )

    {:ok, %{"db" => db_pid}}
  end

  def handle_call({:create}, _from, state) when state != nil do
    statement = "CREATE TABLE users (
            username VARCHAR (50) UNIQUE NOT NULL PRIMARY KEY,
            pwd VARCHAR (50) NOT NULL,
            max_score NUMERIC(9)
          );"
    state["db"] |> Postgrex.query!(statement, [])
    statement = "CREATE TABLE words (
                word VARCHAR (50) UNIQUE NOT NULL PRIMARY KEY
                );"
    state["db"] |> Postgrex.query!(statement, [])
    {:reply, [], state}
  end

  def handle_call({:drop}, _from, state) when state != nil do
    statement = "DROP TABLE IF EXISTS users;"
    state["db"] |> Postgrex.query!(statement, [])
    statement = "DROP TABLE IF EXISTS words"
    state["db"] |> Postgrex.query!(statement, [])
    {:reply, [], state}
  end

  def handle_call({:insert, user}, _from, state) when state != nil do
    statement = "INSERT INTO
            users(username, pwd, max_score)
            VALUES
            ('#{user["username"]}', '#{user["pwd"]}', 0);"
    state["db"] |> Postgrex.query!(statement, [])
    {:reply, [], state}
  end

  def handle_call({:select_user, username}, _from, state) when state != nil do
    statement = "SELECT * FROM users WHERE username = '#{username}'"
    result = state["db"] |> Postgrex.query!(statement, [])
    {:reply, result.rows, state}
  end

  def handle_call({:select_words_local}, _from, state) when state != nil do
    {:ok, contents} = File.read("priv/static/lista_palabras.txt")
    word_list = contents |> String.split(["\n", "\r"], trim: true)
    {:reply, word_list, state}
  end

  def handle_call({:select_words}, _from, state) when state != nil do
    statement = "SELECT * FROM words"
    result = state["db"] |> Postgrex.query!(statement, [])
    word_list = result.rows |> List.flatten()
    {:reply, word_list, state}
  end

  def handle_call({:select_words_by_letter, word}, _from, state) when state != nil do
    letter = word |> String.at(String.length(word) - 1)
    statement = "SELECT * FROM words WHERE word LIKE '#{letter}%'"
    result = state["db"] |> Postgrex.query!(statement, [])
    word_list = result.rows |> List.flatten()
    {:reply, word_list, state}
  end

  def handle_call({:insert_words}, _from, state) when state != nil do
    {:ok, contents} = File.read("priv/static/lista_palabras.txt")
    word_list = contents |> String.split(["\n", "\r"], trim: true)

    word_list
    |> Enum.each(fn word ->
      IO.inspect(word)
      statement = "INSERT INTO
            words(word)
            VALUES
            ('#{word}');"
      state["db"] |> Postgrex.query!(statement, [])
    end)

    {:reply, word_list, state}
  end

  def handle_call({:query, query}, _from, state) when state != nil do
    statement = query
    result = state["db"] |> Postgrex.query!(statement, [])
    {:reply, result.rows, state}
  end
end

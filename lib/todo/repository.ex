defmodule Todo.Repository do
  use GenServer

  # Client
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def create_tables() do
    GenServer.call(__MODULE__, {:create})
  end

  def drop_tables() do
    GenServer.call(__MODULE__, {:drop})
  end

  def insert_user(user) do
    GenServer.call(__MODULE__, {:insert, user})
  end

  def select_user(username) do
    GenServer.call(__MODULE__, {:select_user, username})
  end

  def select_words() do
    GenServer.call(__MODULE__, {:select_words})
  end

  def query(query) do
    GenServer.call(__MODULE__, {:query, query})
  end

  # Server

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
            pwd VARCHAR (50) NOT NULL
          );
          "
    state["db"] |> Postgrex.query!(statement, [])
    {:noreply, state}
  end

  def handle_call({:drop}, _from, state) when state != nil do
    statement = "DROP TABLE IF EXISTS users;"
    result = state["db"] |> Postgrex.query!(statement, [])
    {:noreply, state}
  end

  def handle_call({:insert, user}, _from, state) when state != nil do
    statement = "INSERT INTO
            users(username, pwd)
            VALUES
            ('#{user["username"]}', '#{user["pwd"]}');"
    state["db"] |> Postgrex.query!(statement, [])
    {:noreply, state}
  end

  def handle_call({:select_user, username}, _from, state) when state != nil do
    statement = "SELECT * FROM users WHERE username = '#{username}'"
    result = state["db"] |> Postgrex.query!(statement, [])
    {:reply, result.rows, state}
  end

  # TODO: meter la lista de palabras en la BD, indexarlas y hacer la consulta
  def handle_call({:select_words}, _from, state) when state != nil do
    {:ok, contents} = File.read("priv/static/lista_palabras.txt")
    word_list = contents |> String.split(["\n", "\r"], trim: true)
    {:reply, word_list, state}
  end

  def handle_call({:query, query}, _from, state) when state != nil do
    statement = query
    result = state["db"] |> Postgrex.query!(statement, [])
    {:reply, result.rows, state}
  end
end

defmodule Todo.LoginServer do
  use GenServer

  # Client
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def check_login(user) do
    GenServer.call(__MODULE__, {:check_login, user})
  end

  # Server

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:check_login, user}, _from, state) when state != nil do
    # Por que aqui tengo que usar el prefijo Todo? Y no cuando llamo solo a Server?
    user_row = Todo.Repository.select_user(user.username)

    user =
      case user_row do
        [] ->
          user |> Map.put("state", "no_user")

        [[username, pwd]] ->
          if username == user.username and pwd == user.pwd do
            user |> Map.put("state", "ok")
          else
            user |> Map.put("state", "incorrect_pwd")
          end
      end

    {:reply, user, state}
  end
end

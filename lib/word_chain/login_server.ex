defmodule WordChain.LoginServer do
  @moduledoc """
    Módulo encargado de gestionar las operaciones relacionadas con los usuarios.
  """
  use GenServer

  # ####################################### CLIENT #################################################
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
    Comprueba si el usuario recibido está registrado en el sistema.
  """
  def check_login(user) do
    GenServer.call(__MODULE__, {:check_login, user})
  end

  @doc """
    Inserta un nuevo usuario en el sistema.
  """
  def insert_user(user) do
    GenServer.call(__MODULE__, {:insert_user, user})
  end

  # ####################################### SERVER #################################################
  @doc false
  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:check_login, user}, _from, state) when state != nil do
    # Por que aqui tengo que usar el prefijo WordChain? Y no cuando llamo solo a Server?
    user_row = WordChain.Repository.select_user(user.username)

    user =
      case user_row do
        [] ->
          user |> Map.put("state", "no_user")

        # Underscore prefix until we use it. TODO: max score feature
        [[username, pwd, _score]] ->
          if username == user.username and pwd == user.pwd do
            user |> Map.put("state", "ok")
          else
            user |> Map.put("state", "incorrect_pwd")
          end
      end

    {:reply, user, state}
  end

  def handle_call({:insert_user, user}, _from, state) when state != nil do
    WordChain.Repository.insert_user(user)

    {:reply, user, state}
  end
end

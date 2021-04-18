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
  
    def handle_call({:check_login, user}, _from, state) when state !=nil do
        user_row = Todo.Repository.select_user(user.username) #Por que aqui tengo que usar el prefijo Todo? Y no cuando llamo solo a Server?
        IO.inspect user_row
        response = case user_row do
            [] -> 
                {:error, :no_user, state}
            [[username, pwd]] -> 
                if (username == user.username) and (pwd == user.pwd) do
                    {:reply, user, state}
                else 
                    {:error, :incorrect_pwd, state}
                end
        end
    end


  end
  
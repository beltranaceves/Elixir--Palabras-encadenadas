defmodule Todo.LoginServer do
    use GenServer
  
    # Client
    def start_link(opts) do
      GenServer.start_link(__MODULE__, :ok, opts)
    end
  
    def list() do
      GenServer.call(__MODULE__, {:list})
    end
  
    # Server
  
    def init(:ok) do
      {:ok, []}
    end
  
    def handle_call({:list}, _from, state) when state !=nil do
      {:reply, state, state}
    end


  end
  
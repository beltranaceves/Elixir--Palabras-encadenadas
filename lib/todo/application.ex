defmodule Todo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    var_port = get_port()

    children = [
      {Plug.Cowboy, scheme: :http, plug: Todo.Router, options: [port: var_port]},
      {Todo.Server, [name: Todo.Server]},
      {Todo.LoginServer, [name: Todo.LoginServer]},
      {Todo.GameServer, [name: Todo.GameServer]},
      {Todo.Repository, [name: Todo.Repository]}
    ]

    Logger.info("Starting application on port #{var_port}.")
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Todo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_port() do #TODO: fix bug siempre intenta abrir el puerto 3000, aunque haga la comprobacion

    if is_nil(System.get_env("PORT")) do
      3000
    else
      String.to_integer(System.get_env("PORT"))
    end
  end
end

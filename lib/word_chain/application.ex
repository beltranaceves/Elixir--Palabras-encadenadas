defmodule WordChain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {WordChain.LoginServer, :start_link, [[name: WordChain.LoginServer]]},
      {WordChain.GameServer, :start_link, [[name: WordChain.GameServer]]},
      {WordChain.Repository, :start_link, [[name: WordChain.Repository]]},
      {Plug.Cowboy, :http, [WordChain.Router, [], [ref: WordChain_Router_4000]]}
    ]

    opts = [name: WordChain.MySupervisor]
    WordChain.MySupervisor.start_link(children, opts)
  end
end

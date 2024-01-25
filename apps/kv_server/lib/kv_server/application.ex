defmodule KVServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = System.get_env("PORT", "4040") |> String.to_integer()

    children = [
      {Task.Supervisor, name: KVServer.TaskSupervisor},
      # By default, the `Task` module's `child_spec/1` hard code the `restart`
      # option as `temporary`. In the server acceptor process, however, it's
      # necessary to restart it in the case of failures.
      #
      # While one could also implement the server's acceptor as a GenServer,
      # we could also use a task and override it's `restart` option by using
      # the `Supervisor.child_spec/2` function.
      Supervisor.child_spec(
        {Task, fn -> KVServer.accept(port) end},
        restart: :permanent
      )
    ]

    opts = [strategy: :one_for_one, name: KVServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

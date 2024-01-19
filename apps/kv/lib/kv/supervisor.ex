defmodule KV.Supervisor do
  use Supervisor

  @spec start_link([Supervisor.option()]) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  @impl Supervisor
  def init([]) do
    children = [
      {KV.Registry, name: KV.Registry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

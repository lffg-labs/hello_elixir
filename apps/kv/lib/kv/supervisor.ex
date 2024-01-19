defmodule KV.Supervisor do
  use Supervisor

  @spec start_link([Supervisor.option()]) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  @impl Supervisor
  def init([]) do
    children = [
      # `KV.BucketSupervisor` must be started *before* `KV.Registry`, as the
      # registry invokes the bucket supervisor when creating new buckets.
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      {KV.Registry, name: KV.Registry}
    ]

    # If `KV.Registry` crashes, `KV.BucketSupervisor` and all its children (all
    # the buckets) must terminate too. Otherwise, with the new registry, each
    # of the old buckets would be unreachable. I.e., `:one_for_one` would cause
    # a leak.
    Supervisor.init(children, strategy: :one_for_all)
  end
end

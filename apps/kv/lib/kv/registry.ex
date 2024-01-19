defmodule KV.Registry do
  use GenServer

  @type server() :: GenServer.server()
  @type name() :: String.t()

  #
  # Client API
  #

  @doc """
  Starts the registry.
  """
  @spec start_link() :: GenServer.on_start()
  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @doc """
  Looks up the bucket pid for the given `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  @spec lookup(server(), name()) :: {:ok, pid()} | :error
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Asynchronously ensure that there is a bucket associated with the given `name`
  in `server`.
  """
  @spec create(server(), name()) :: :ok
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  #
  # Server callbacks
  #

  @impl GenServer
  def init([]) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  @impl GenServer
  def handle_call({:lookup, name}, _from, state) do
    {names, _refs} = state
    {:reply, Map.fetch(names, name), state}
  end

  @impl GenServer
  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, bucket} = KV.Bucket.start_link()
      ref = Process.monitor(bucket)

      names = Map.put(names, name, bucket)
      refs = Map.put(refs, ref, name)

      {:noreply, {names, refs}}
    end
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl GenServer
  def handle_info(msg, state) do
    import Logger
    info("Unexpected message in #{__MODULE__}: #{inspect(msg)}")
    {:noreply, state}
  end
end

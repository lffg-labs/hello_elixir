defmodule KV.Bucket do
  use Agent

  @type t :: pid()

  @type k :: term()
  @type v :: term()

  @doc """
  Starts a new bucket.
  """
  @spec start_link() :: Agent.on_start()
  @spec start_link(GenServer.options()) :: Agent.on_start()
  def start_link(opts \\ []) do
    Agent.start_link(fn -> %{} end, opts)
  end

  @doc """
  Gets a value from the bucket by the given key.
  """
  @spec get(t(), k()) :: v()
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Puts the given value for the given key in the bucket.
  """
  @spec put(t(), k(), v()) :: :ok
  def put(bucket, key, val) do
    Agent.update(bucket, &Map.put(&1, key, val))
  end
end

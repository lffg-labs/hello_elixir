defmodule KVServer.Command do
  @doc """
  Runs the given command.
  """
  def run(command)

  def run({:create, bucket}) do
    :ok = KV.Registry.create(KV.Registry, bucket)
    {:ok, "OK\n"}
  end

  def run({:get, bucket, key}) do
    lookup_bucket(bucket, fn pid ->
      value = KV.Bucket.get(pid, key) || "<nil>"
      {:ok, "#{value}\n"}
    end)
  end

  def run({:put, bucket, key, value}) do
    lookup_bucket(bucket, fn pid ->
      KV.Bucket.put(pid, key, value)
      {:ok, "OK\n"}
    end)
  end

  def run({:delete, bucket, key}) do
    lookup_bucket(bucket, fn pid ->
      KV.Bucket.delete(pid, key)
      {:ok, "OK\n"}
    end)
  end

  defp lookup_bucket(bucket, cb) do
    case KV.Registry.lookup(KV.Registry, bucket) do
      {:ok, pid} -> cb.(pid)
      :error -> {:error, :bucket_not_found, bucket}
    end
  end

  @doc ~S"""
  Parses the given `line` into a command.

  ## Examples

      iex> KVServer.Command.parse("CREATE shopping\n")
      {:ok, {:create, "shopping"}}

      iex> KVServer.Command.parse("CREATE    shopping  \n")
      {:ok, {:create, "shopping"}}

      iex> KVServer.Command.parse("PUT shopping milk 1")
      {:ok, {:put, "shopping", "milk", "1"}}

      iex> KVServer.Command.parse("GET shopping milk")
      {:ok, {:get, "shopping", "milk"}}

      iex> KVServer.Command.parse("DELETE shopping eggs")
      {:ok, {:delete, "shopping", "eggs"}}

  Unknown commands or commands with the wrong number of arguments return
  an error:

      iex> KVServer.Command.parse("UNKNOWN shopping eggs")
      {:error, :unknown_command}

      iex> KVServer.Command.parse("GET shopping")
      {:error, :unknown_command}
  """
  def parse(line) do
    case String.split(line) do
      ["CREATE", bucket] -> {:ok, {:create, bucket}}
      ["PUT", bucket, key, value] -> {:ok, {:put, bucket, key, value}}
      ["GET", bucket, key] -> {:ok, {:get, bucket, key}}
      ["DELETE", bucket, key] -> {:ok, {:delete, bucket, key}}
      _ -> {:error, :unknown_command}
    end
  end
end

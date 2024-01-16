defmodule MyFile.Descriptor do
  defstruct [:path, :pid]

  @type t() :: %__MODULE__{path: Path.t(), pid: pid()}

  #
  # Client functions.
  #

  @spec open(Path.t()) :: {:ok, t()}
  def open(path) do
    parent = self()

    pid =
      spawn_link(fn ->
        send(self(), {:io_op_req, :open})
        loop(parent, path)
      end)

    fd = %__MODULE__{path: path, pid: pid}

    receive do
      {:io_op_resp, :open} -> {:ok, fd}
    end
  end

  @spec read(t()) :: {:ok, any()}
  def read(%__MODULE__{pid: pid}) do
    send(pid, {:io_op_req, :read})

    receive do
      {:io_op_resp, :read, data} -> {:ok, data}
    end
  end

  @spec close(t()) :: :ok
  def close(%__MODULE__{pid: pid}) do
    send(pid, {:io_op_req, :close})

    receive do
      {:io_op_resp, :close} -> :ok
    end
  end

  #
  # Server function.
  #

  defp loop(parent, path) do
    receive do
      {:io_op_req, :open} ->
        IO.puts("[file] opened [#{path}]")
        Process.flag(:trap_exit, true)
        send(parent, {:io_op_resp, :open})
        loop(parent, path)

      {:io_op_req, :read} ->
        IO.puts("[file] reading from [#{path}]")
        # Fake data. The file system isn't important to this example.
        send(parent, {:io_op_resp, :read, "some data..."})
        loop(parent, path)

      {:io_op_req, :close} ->
        # Notice that this case doesn't call `loop/2`.
        IO.puts("[file] closing file [#{path}]")
        send(parent, {:io_op_resp, :close})

      {:EXIT, origin, reason} ->
        IO.puts("[file] got exit from #{inspect(origin)} of reason #{inspect(reason)}")
        send(self(), {:io_op_req, :close})
        loop(parent, path)

      unknown ->
        raise "unknown message: #{inspect(unknown)}"
    end
  end
end

defmodule MyFile do
  alias MyFile.Descriptor, as: Fd

  @spec open(Path.t()) :: {:ok, Fd.t()}
  def open(path), do: Fd.open(path)

  @spec read(Path.t()) :: {:ok, any()}
  def read(fd), do: Fd.read(fd)

  @spec read(Path.t()) :: :ok
  def close(fd), do: Fd.close(fd)
end

IO.puts("[main] will open file")

{:ok, fd} = MyFile.open("/etc/passwd")
IO.puts("[main] got fd #{inspect(fd)}")

{:ok, data} = MyFile.read(fd)
IO.puts("[main] got file contents: #{inspect(data)}")

:ok = MyFile.close(fd)
IO.puts("[main] closed file")

# Ensure the file process has indeed finished.
false = Process.alive?(fd.pid)

String.duplicate("-", 100) |> IO.puts()

# Now we'll try to open a file from a process which will fail *before* closing
# the file. We shall see that, since the file descriptor process traps exists,
# it will be able to properly clean its resources up.

spawn(fn ->
  IO.puts("[proc] started #{inspect(self())}")
  {:ok, fd} = MyFile.open("/etc/hosts")
  IO.puts("[main] got fd #{inspect(fd)}")
  true = Process.alive?(fd.pid)

  IO.puts("[proc] will exit abruptly...")
  # The file wasn't explicitly closed...
  exit(:whoops)
end)

Process.sleep(1000)
String.duplicate("-", 100) |> IO.puts()
IO.puts("[main] done")

# Expected output
# ===============

# $ mix run experiments/resource_mgmt.ex
#
# [main] will open file
# [file] opened [/etc/passwd]
# [main] got fd %MyFile.Descriptor{path: "/etc/passwd", pid: #PID<0.122.0>}
# [file] reading from [/etc/passwd]
# [main] got file contents: "some data..."
# [file] closing file [/etc/passwd]
# [main] closed file
# --------------------------------------------------------------------------------------------------
# [proc] started #PID<0.123.0>
# [file] opened [/etc/hosts]
# [main] got fd %MyFile.Descriptor{path: "/etc/hosts", pid: #PID<0.124.0>}
# [proc] will exit abruptly...
# [file] got exit from #PID<0.123.0> of reason :whoops
# [file] closing file [/etc/hosts]
# --------------------------------------------------------------------------------------------------
# [main] done

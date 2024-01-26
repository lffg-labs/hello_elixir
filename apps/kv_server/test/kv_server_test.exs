defmodule KVServerTest do
  use ExUnit.Case

  @moduletag :capture_log

  setup do
    Application.put_env(:kv_server, :logger, :console, level: :warning)

    Application.stop(:kv)
    :ok = Application.start(:kv)
  end

  setup do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 4040, opts)
    {:ok, "Welcome.\n"} = :gen_tcp.recv(socket, 0, 500)
    {:ok, "\n"} = :gen_tcp.recv(socket, 0, 500)
    %{socket: socket}
  end

  test "server interaction", %{socket: socket} do
    assert send_and_recv(socket, "UNKNOWN shopping\n") == "Unknown command.\n"
  end

  defp send_and_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command)
    {:ok, data} = :gen_tcp.recv(socket, 0, 500)
    data
  end
end

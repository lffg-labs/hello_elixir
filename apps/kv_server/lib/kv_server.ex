defmodule KVServer do
  require Logger

  def accept(port) do
    {:ok, listen_socket} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :line,
        active: false,
        reuseaddr: true
      ])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(listen_socket)
  end

  # this acceptor is fragile and if it errors out, currently, the application
  # won't be able to serve any more requests
  defp loop_acceptor(listen_socket) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)

    {:ok, pid} =
      Task.Supervisor.start_child(KVServer.TaskSupervisor, fn ->
        serve(client_socket)
      end)

    :ok = :gen_tcp.controlling_process(client_socket, pid)

    loop_acceptor(listen_socket)
  end

  defp serve(socket) do
    {:ok, addr} = :inet.peername(socket)
    addr = addr_string(addr)

    Logger.info("serving #{addr}")
    :gen_tcp.send(socket, "Welcome.\n\n")
    serve(socket, addr)
  end

  defp serve(socket, addr) do
    msg =
      with {:ok, data} <- read_line(socket),
           {:ok, command} <- KVServer.Command.parse(data),
           do: KVServer.Command.run(command)

    :ok = write_line(socket, addr, msg)
    serve(socket, addr)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, _addr, {:ok, text}) do
    :gen_tcp.send(socket, text)
  end

  defp write_line(socket, _addr, {:error, :unknown_command}) do
    :gen_tcp.send(socket, "Unknown command.\n")
  end

  defp write_line(_socket, addr, {:error, :closed}) do
    # Close this handler process normally if the client closes the connection.
    Logger.info("client #{addr} disconnected")
    exit(:shutdown)
  end

  defp write_line(socket, _addr, {:error, error}) do
    :gen_tcp.send(socket, "Unknown error.\n")
    Logger.warning("unknown error #{inspect(error)}")
    exit(error)
  end

  defp addr_string({{a, b, c, d}, port}) do
    "#{a}.#{b}.#{c}.#{d}:#{port}"
  end
end

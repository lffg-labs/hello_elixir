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
    Logger.info("serving #{inspect(addr)}")

    answer_with_lines(socket)
  end

  defp answer_with_lines(socket) do
    socket
    |> read_line()
    |> write_line(socket)

    answer_with_lines(socket)
  end

  defp read_line(socket) do
    # this will error out when the client closes the connection
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end

defmodule MyIO do
  @spec log(String.t(), String.Chars.t()) :: :ok
  def log(name, msg) do
    IO.puts("[#{name}#{inspect(self())}] #{msg}")
  end
end

MyIO.log("main", "started")

{:ok, sup} = Task.Supervisor.start_link()

# Note the "async_nolink/2" below.
task =
  Task.Supervisor.async_nolink(sup, fn ->
    MyIO.log("task", "started")
    raise "whoops!"
  end)

Process.sleep(10)

# Code won't even reach this point, as the task process exited abnormally. As
# such a process is linked with its parent (this main one), both exit.

MyIO.log("main", "will await task")

# Here one can't use await since await expects a successful result.
{:exit, rt_error} = Task.shutdown(task) |> dbg

MyIO.log("main", "finished")

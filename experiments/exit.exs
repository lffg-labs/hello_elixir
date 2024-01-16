defmodule Mod do
  def start do
    parent = self()

    spawn_link(fn ->
      Process.sleep(1)
      run_proc(parent)
    end)
  end

  def run_proc(parent, 5) do
    IO.puts("[proc] in the last process (5)")
    exit(:testing_exit)

    send(parent, :done)
  end

  def run_proc(parent, i) do
    IO.puts("[proc] in the process (#{i})")
    Process.sleep(250)
    run_proc(parent, i + 1)
  end

  def run_proc(parent), do: run_proc(parent, 1)
end

# One doesn't need to trap exits _before_ spawning. However, the flag should be
# set _before_ the process exits, obviously.
Process.flag(:trap_exit, true)

pid = Mod.start()
IO.puts("[main] stated #{inspect(pid)}")

receive do
  :done ->
    nil

  # Since one's trapping exits.
  {:EXIT, origin, reason} ->
    IO.puts(~s([main] caught exit from #{inspect(origin)} with reason "#{inspect(reason)}"))
end

IO.puts("[main] done")

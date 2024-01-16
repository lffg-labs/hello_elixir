try do
  IO.puts("allocating resource...")
  raise "whoops!"
  # would have the same effect with exits, e.g. with `exit(:"...")`
after
  IO.puts("cleaning up before blowing up...")
end

IO.puts("never will reach here.")

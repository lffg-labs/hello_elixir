import Config

config :kv_server, :server, port: System.get_env("PORT", "4040") |> String.to_integer()

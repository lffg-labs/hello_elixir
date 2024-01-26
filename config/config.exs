import Config

config :logger, :console,
  level: if(config_env() == :test, do: :warning, else: :info),
  format: "$date $time [$level] $metadata$message\n",
  metadata: [:user_id]

use Mix.Config

config :logger, :handle_otp_reports, false

config :timber,
  api_key: "api_key",
  capture_errors: true

defmodule Timber.Exceptions.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    disable_tty? = Application.get_env(:timber_exceptions, :disable_tty?, false)

    if disable_tty? do
      Timber.Exceptions.disable_tty()
    end

    children = []
    opts = [strategy: :one_for_one, name: Timber.Exceptions.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Timber.Exceptions.SimpleTestGenServer do
  @moduledoc false

  use GenServer

  def start_link(pid) do
    GenServer.start_link(__MODULE__, pid)
  end

  def init(pid) do
    {:ok, pid}
  end

  def terminate(_, state) do
    send(state, :terminating)
  end
end

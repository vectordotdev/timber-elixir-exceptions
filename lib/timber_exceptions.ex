defmodule Timber.Exceptions do
  @moduledoc """
  Documentation for Timber.Exceptions.
  """

  @doc """
  Adds the Timber exception handler

  The Timber exception handler (`Timber.Exceptions.ErrorLogger`) is added as a
  report handler for `:error_logger` if it has not already been added.
  """
  @spec add_handler() :: :gen_event.add_handler_ret()
  def add_handler() do
    existing_handlers = :gen_event.which_handlers(:error_logger)

    if !(Timber.Exceptions.ErrorLogger in existing_handlers) do
      :error_logger.add_report_handler(Timber.Exceptions.ErrorLogger)
    end
  end

  @doc """
  Removes the Timber exception handler
  """
  @spec remove_handler() :: :gen_event.del_handler_ret()
  def remove_handler() do
    :error_logger.delete_report_handler(Timber.Exceptions.ErrorLogger)
  end

  @doc """
  Restores the tty output for the error logger

  The default `:error_logger_tty_h` report handler is added for `:error_logger`.
  """
  @spec restore_tty() :: :gen_event.add_handler_ret()
  def restore_tty() do
    :error_logger.tty(true)
  end

  @doc """
  Disables the default tty output for the error logger
  """
  @spec disable_tty() :: :ok
  def disable_tty() do
    :error_logger.tty(false)
  end
end

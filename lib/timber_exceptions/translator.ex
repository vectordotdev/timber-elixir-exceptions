defmodule Timber.Exceptions.Translator do
  @moduledoc """
  This module implements a Logger translator to take advantage of
  the richer metadata available from Logger in OTP 21 and Elixir 1.7+.

  Including the translator allows for crash reasons and stacktraces to be
  included as structured metadata within Timber.

  The translator depends on using Elixir's internal Logger.Translator, and
  is not compatible with other translators as a Logger event can only be
  translated once.

  To install, add the translator in your application's start function:
  ```
  # ...
  :ok = Logger.add_translator({Timber.Exceptions.Translator, :translate})

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
  ```
  """

  @max_backtrace_size 20

  def translate(min_level, level, kind, message) do
    case Logger.Translator.translate(min_level, level, kind, message) do
      {:ok, char, metadata} ->
        new_metadata = transform_metadata(metadata)

        {:ok, char, new_metadata}

      {:ok, char} ->
        {:ok, char}

      :skip ->
        :skip

      :none ->
        :none
    end
  end

  def transform_metadata(nil), do: []

  def transform_metadata(metadata) do
    with {:ok, crash_reason} <- Keyword.fetch(metadata, :crash_reason),
         {:ok, error} <- get_error(crash_reason) do
      event = %{
        error: error
      }

      Keyword.merge([event: event], metadata)
    else
      _ ->
        metadata
    end
  end

  defp get_error({{%{__exception__: true} = error, stacktrace}, _stack})
       when is_list(stacktrace) do
    {:ok, build_error(error, stacktrace)}
  end

  defp get_error({%{__exception__: true} = error, stacktrace}) when is_list(stacktrace) do
    {:ok, build_error(error, stacktrace)}
  end

  defp get_error({{_type, reason}, stacktrace}) when is_list(stacktrace) do
    {:ok, build_error(reason, stacktrace)}
  end

  defp get_error({error, stacktrace}) when is_list(stacktrace) do
    {:ok, build_error(error, stacktrace)}
  end

  defp get_error(_) do
    {:error, :no_info}
  end

  defp build_error(%{__exception__: true, __struct__: module} = error, stacktrace) do
    message = Exception.message(error)
    module_name = Timber.Utils.Module.name(module)

    %{
      message: message,
      name: module_name,
      backtrace: build_backtrace(stacktrace)
    }
  end

  defp build_error(error, stacktrace) do
    ErlangError.normalize(error, stacktrace)
    |> build_error(stacktrace)
  end

  defp build_backtrace([trace | _] = backtrace) when is_map(trace) do
    Enum.slice(backtrace, 0..(@max_backtrace_size - 1))
  end

  defp build_backtrace([stack | _rest] = stacktrace) when is_tuple(stack) do
    stacktrace_to_backtrace(stacktrace)
  end

  defp build_backtrace(_) do
    []
  end

  defp stacktrace_to_backtrace(stacktrace) do
    # arity is an integer or list of arguments
    Enum.map(stacktrace, fn {module, function, arity, location} ->
      arity =
        case arity do
          arity when is_list(arity) -> length(arity)
          _ -> arity
        end

      file =
        Keyword.get(location, :file)
        |> Kernel.to_string()

      line = Keyword.get(location, :line)

      %{
        function: Exception.format_mfa(module, function, arity),
        file: file,
        line: line
      }
    end)
  end
end

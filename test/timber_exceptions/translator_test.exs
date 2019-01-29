defmodule Timber.Exceptions.TranslatorTest do
  use ExUnit.Case

  import Timber.Exceptions.TestHelpers

  alias Timber.HTTPClients.Fake, as: FakeHTTPClient

  alias Timber.LoggerBackends.InMemory
  alias Timber.Exceptions.{TestGenServer, SimpleTestGenServer}
  alias Timber.LoggerBackends.HTTP

  defp add_timber_logger_translator() do
    :ok = Logger.add_translator({Timber.Exceptions.Translator, :translate})

    ExUnit.Callbacks.on_exit(fn ->
      Logger.remove_translator({Timber.Exceptions.Translator, :translate})
    end)
  end

  test "logs errors from crashed Task" do
    add_timber_logger_translator()
    add_in_memory_logger_backend(self())

    {:ok, pid} =
      Task.start(fn ->
        raise "Task Error"
      end)

    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, InMemory, :get)

    assert %{
             error: %{
               name: "RuntimeError",
               message: "Task Error",
               backtrace: [_line1, _line2, _line3]
             }
           } = Keyword.get(metadata, :event)

    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors from GenServer throw" do
    Process.flag(:trap_exit, true)
    add_timber_logger_translator()
    add_in_memory_logger_backend(self())

    {:ok, pid} = TestGenServer.start_link(self())
    TestGenServer.do_throw(pid)
    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, InMemory, :get)

    assert %{
             error: %{
               name: "ErlangError",
               message: message
             }
           } = Keyword.get(metadata, :event)

    assert message =~ ~r/Erlang error: "I am throwing"/i

    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors from GenServer abnormal exit" do
    Process.flag(:trap_exit, true)
    add_timber_logger_translator()
    add_in_memory_logger_backend(self())

    {:ok, pid} = TestGenServer.start_link(self())
    TestGenServer.bad_exit(pid)
    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, InMemory, :get)

    assert %{
             error: %{
               name: "ErlangError",
               message: message
             }
           } = Keyword.get(metadata, :event)

    assert message =~ ~r/Erlang error: :bad_exit/i
    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors from GenServer handle_call crash" do
    add_timber_logger_translator()
    add_in_memory_logger_backend(self())
    Process.flag(:trap_exit, true)

    {:ok, pid} = TestGenServer.start_link(self())

    assert catch_exit(TestGenServer.divide_call(pid, 1, 0))
    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, InMemory, :get)

    assert %{
             error: %{
               message: "bad argument in arithmetic expression",
               name: "ArithmeticError",
               backtrace: [_, _, _, _]
             }
           } = Keyword.get(metadata, :event)

    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors from GenServer handle_info crash" do
    add_timber_logger_translator()
    add_in_memory_logger_backend(self())
    Process.flag(:trap_exit, true)

    {:ok, pid} = TestGenServer.start_link(self())

    TestGenServer.divide(pid, 1, 0)
    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, InMemory, :get)

    assert %{
             error: %{
               message: "bad argument in arithmetic expression",
               name: "ArithmeticError",
               backtrace: [_, _, _, _]
             }
           } = Keyword.get(metadata, :event)

    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors from GenServer raise" do
    Process.flag(:trap_exit, true)
    add_timber_logger_translator()
    add_in_memory_logger_backend(self())

    {:ok, pid} = TestGenServer.start_link(self())
    TestGenServer.raise(pid)
    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, InMemory, :get)

    assert %{
             error: %{
               message: "raised error",
               name: "RuntimeError",
               backtrace: [_, _, _, _]
             }
           } = Keyword.get(metadata, :event)

    assert Keyword.get(metadata, :pid) == pid
  end

  skip_min_elixir_version("1.4")

  test "logs errors from GenServer unexpected message in handle_info/2" do
    add_timber_logger_translator()
    add_in_memory_logger_backend(self())

    {:ok, pid} = SimpleTestGenServer.start_link(self())
    send(pid, :unexpected)
    assert_receive :ok

    [{_level, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, InMemory, :get)

    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors arbitrary errors received by :error_logger" do
    add_timber_logger_translator()
    add_in_memory_logger_backend(self())

    :error_logger.error_msg("Failed to start Ranch listener ~p", [self()])

    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, InMemory, :get)

    assert Keyword.get(metadata, :pid) == self()
  end

  test "logs errors from spawned process crash" do
    add_timber_logger_translator()
    add_in_memory_logger_backend(self())

    spawn(fn ->
      raise "Error"
    end)

    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, InMemory, :get)

    assert %{
             error: %{
               backtrace: [
                 %{
                   file: "test/timber_exceptions/translator_test.exs",
                   function: _,
                   line: _
                 }
               ],
               message: "Error",
               name: "RuntimeError"
             }
           } = Keyword.get(metadata, :event)
  end

  test "Logger events are encodable by the HTTP backend" do
    {:ok, state} = HTTP.init(HTTP, http_client: FakeHTTPClient)
    add_timber_logger_translator()
    add_in_memory_logger_backend(self())

    Task.start(fn ->
      Timber.CurrentContext.add(%{a: :b})

      raise "Task Error"
    end)

    assert_receive :ok

    [{:error, pid, {Logger, msg, ts, metadata}}] = :gen_event.call(Logger, InMemory, :get)

    entry = {:error, pid, {Logger, msg, ts, metadata}}

    {:ok, state} = HTTP.handle_event(entry, state)

    HTTP.handle_event(:flush, state)

    calls = FakeHTTPClient.get_async_request_calls()
    assert length(calls) == 1

    call = Enum.at(calls, 0)
    assert elem(call, 0) == :post
    assert elem(call, 1) == "https://logs.timber.io/frames"

    vsn = Application.spec(:timber, :vsn)

    assert elem(call, 2) == %{
             "Authorization" => "Basic YXBpX2tleQ==",
             "Content-Type" => "application/msgpack",
             "User-Agent" => "timber-elixir/#{vsn}"
           }

    encoded_body = event_entry_to_msgpack(entry)
    assert elem(call, 3) == encoded_body
  end
end

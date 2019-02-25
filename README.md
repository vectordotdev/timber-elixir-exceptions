# 🌲 Timber exception capturing for Elixir

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md)
[![Hex.pm](https://img.shields.io/hexpm/v/timber_exceptions.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber_exceptions)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber_exceptions/index.html)
[![Build Status](https://travis-ci.org/timberio/timber-elixir-exceptions.svg?branch=master)](https://travis-ci.org/timberio/timber-elixir-exceptions)

The Timber Exceptions library provides enhanced logging of exceptions that occur
in your Elixir software.

## Installation

1. Ensure that you have both `:timber` (version 3.0.0 or later) and `:timber_exceptions` listed
as dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        {:timber, "~> 3.1"},
        {:timber_exceptions, "~> 2.0"}
      ]
    end
    ```

2. Run `mix deps.get` to install the dependencies.

3. Add the translator in your application's `start/2` function:

    ```elixir
    defmodule MyApp
      use Applictation
      
      def start(_type, _args) do
        # ADD THE FOLLOW LINE:
        :ok = Logger.add_translator({Timber.Exceptions.Translator, :translate})

        opts = [strategy: :one_for_one, name: MyApp.Supervisor]
        Supervisor.start_link(children, opts)
      end
    end
    ```

## License

This project is licensed under the ISC License - see [LICENSE] for more details.

# 🌲 Timber exception capturing for Elixir

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md)
[![Hex.pm](https://img.shields.io/hexpm/v/timber-exceptions.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber-exceptions)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber-exceptions/index.html)
[![Build Status](https://travis-ci.org/timberio/timber-elixir-exceptions.svg?branch=master)](https://travis-ci.org/timberio/timber-elixir-exceptions)

The Timber Exceptions library provides enhanced logging of exceptions that occur
in your Elixir software.

## Installation

Ensure that you have both `:timber` (version 3.0.0 or later) and `:timber_ecto` listed
as dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:timber, "~> 3.0"},
    {:timber_exceptions, "~> 1.0"}
  ]
end
```

Then run `mix deps.get`.

Inside your Elixir application's `start/2` callback, call
`Timber.Exceptions.add_handler()`. The rest is handled for you!

## License

This project is licensed under the ISC License - see [LICENSE] for more details.

# Changelog

This covers changes for versions 2.0 and higher. The changelog for 1.x releases
can be found in the [v1.x
branch](https://github.com/timberio/timber-elixir-exceptions/blob/v1.x/CHANGELOG.md).

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic
Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 2.0.0 - 2019-01-02

### Added

  - Added a Logger translator to handle exception capturing with Elixir 1.7 and
    OTP 21

### Removed

  - Removed support for versions of Elixir 1.6 and below
  - Removed the Erlang `:error_logger` handler in favor of the Elixir 1.7 Logger
    translator
    
[Unreleased]: https://github.com/timberio/timber-elixir-exceptions/compare/v2.0.0...HEAD

# Membrane Scissors plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_scissors_plugin.svg)](https://hex.pm/packages/membrane_scissors_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_scissors_plugin/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_scissors_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_scissors_plugin)

Element for cutting off parts of the stream.

## Usage

The following setup will preserve one buffer per 10 milliseconds (assuming each buffer lasts `caps.duration`):

```elixir
%Membrane.Scissors{
  intervals: Stream.iterate(0, & &1 + Membrane.Time.Milliseconds(10)) |> Stream.map(&{&1, 1}),
  interval_duration_unit: :buffers,
  buffer_duration: fn _buffer, caps -> caps.duration end
}
```

Note that particular codecs may allow the stream to be cut at specific points only or forbid cutting at all.

## Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
{:membrane_scissors_plugin, "~> 0.5.0"}
```

## Copyright and License

Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_scissors_plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_scissors_plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)

# Membrane Scissors plugin

[![Star Membrane on GitHub ★](https://img.shields.io/github/stars/membraneframework/membrane_core?style=flat&logo=github&label=Star%20Membrane%20on%20GitHub%20%E2%98%85&color=blue)](https://github.com/membraneframework/membrane_core)
[![Hex.pm](https://img.shields.io/hexpm/v/membrane_scissors_plugin.svg)](https://hex.pm/packages/membrane_scissors_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_scissors_plugin/)
[![CI](https://github.com/membraneframework/membrane_scissors_plugin/actions/workflows/ci.yml/badge.svg)](https://github.com/membraneframework/membrane_scissors_plugin/actions/workflows/ci.yml)

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
	{:membrane_scissors_plugin, "~> 0.8.2"}
```

## Copyright and License

Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_scissors_plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_scissors_plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)

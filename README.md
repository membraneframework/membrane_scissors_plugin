# Membrane Multimedia Framework: Scissors Element

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_element_scissors.svg)](https://hex.pm/packages/membrane_element_scissors)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_element_scissors/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane-element-scissors.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane-element-scissors)

Element for cutting off parts of the stream.

## Usage

The following setup will preserve one buffer per 10 milliseconds (assuming each buffer lasts `caps.duration`):

```elixir
%Membrane.Element.Scissors{
  intervals: Stream.iterate(0, & &1 + Membrane.Time.Milliseconds(10)) |> Stream.map(&{&1, 1}),
  interval_duration_unit: :buffers,
  buffer_duration: fn _buffer, caps -> caps.duration end
}
```

Note that particular codecs may allow the stream to be cut at specific points only or forbid cutting at all.

## Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
{:membrane_element_scissors, "~> 0.1.0"}
```

## Copyright and License

Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-element-scissors)

[![Software Mansion](https://membraneframework.github.io/static/logo/swm_logo_readme.png)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-element-scissors)

Licensed under the [Apache License, Version 2.0](LICENSE)

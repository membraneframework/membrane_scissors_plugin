defmodule Membrane.Element.ScissorsTest do
  use Bunch
  use ExUnit.Case
  alias Membrane.Element.Scissors

  test "cuts the stream properly by given time" do
    integration_test(
      0..20,
      [2, 3, 6, 7, 8, 9, 12, 13, 14, 16, 17],
      [{1, 1}, {3, 2}, {6, 3}],
      Ratio.new(1, 2),
      fn buffer, _caps -> buffer.payload != 15 end,
      :time
    )
  end

  test "cuts the stream properly by given buffer count" do
    integration_test(
      0..20,
      [2, 6, 7, 12, 14, 15],
      [{1, 1}, {3, 2}, {6, 3}],
      Ratio.new(1, 2),
      fn buffer, _caps -> buffer.payload != 13 end,
      :buffers
    )
  end

  defp integration_test(in_payloads, out_payloads, intervals, duration, filter, unit) do
    import Membrane.ParentSpec
    import Membrane.Testing.Assertions
    alias Membrane.Testing

    elements = [
      source: %Testing.Source{
        output: in_payloads
      },
      scissors: %Scissors{
        buffer_duration: fn _buffer, _caps -> duration end,
        intervals: intervals,
        interval_duration_unit: unit,
        filter: filter
      },
      sink: Testing.Sink
    ]

    links = [link(:source) |> to(:scissors) |> to(:sink)]

    {:ok, pipeline} =
      Testing.Pipeline.start_link(%Testing.Pipeline.Options{
        elements: elements,
        links: links
      })

    Membrane.Pipeline.play(pipeline)

    Enum.each(out_payloads, fn expected_payload ->
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: payload})
      assert payload == expected_payload
    end)

    assert_end_of_stream(pipeline, :sink)
  end
end

defmodule Membrane.ScissorsTest do
  use Bunch
  use ExUnit.Case
  alias Membrane.Scissors

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
    import Membrane.ChildrenSpec
    import Membrane.Testing.Assertions
    alias Membrane.Testing

    source = %Testing.Source{
      output: in_payloads
    }

    scissors = %Scissors{
      buffer_duration: fn _buffer, _caps -> duration end,
      intervals: intervals,
      interval_duration_unit: unit,
      filter: filter
    }

    structure = [
      child(:source, source) |> child(:scissors, scissors) |> child(:sink, Testing.Sink)
    ]

    {:ok, _pipeline_supervisor, pipeline} =
      Testing.Pipeline.start_link_supervised(structure: structure)

    Enum.each(out_payloads, fn expected_payload ->
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: payload})
      assert payload == expected_payload
    end)

    assert_end_of_stream(pipeline, :sink)
    refute_sink_buffer(pipeline, :sink, _, 0)
  end
end

defmodule Membrane.Element.ScissorsTest do
  use Bunch
  use ExUnit.Case
  alias Membrane.Element.Scissors

  test "cuts buffers properly by time" do
    buffers =
      process_buffers(
        0..20,
        [{1, 1}, {3, 2}, {6, 3}],
        Ratio.new(1, 2),
        fn buffer, _caps -> buffer != 15 end,
        :time
      )

    assert buffers == [2, 3, 6, 7, 8, 9, 12, 13, 14, 16, 17]
  end

  test "cuts buffers properly by buffer count" do
    buffers =
      process_buffers(
        0..20,
        [{1, 1}, {3, 2}, {6, 3}],
        Ratio.new(1, 2),
        fn buffer, _caps -> buffer != 13 end,
        :buffers
      )

    assert buffers == [2, 6, 7, 12, 14, 15]
  end

  defp process_buffers(buffers, cuts, duration, filter, unit) do
    {:ok, state} =
      %Scissors{
        buffer_duration: fn _buffer, _caps -> duration end,
        cuts: cuts,
        duration_unit: unit,
        filter: filter
      }
      |> Scissors.handle_init()

    ctx = %{pads: %{input: %{caps: nil}}}

    buffers
    |> Enum.flat_map_reduce(state, fn buffer, state ->
      {{:ok, actions}, state} = Scissors.handle_process(:input, buffer, ctx, state)
      {actions, state}
    end)
    ~> ({result, _state} -> result)
    |> Bunch.KVEnum.filter_by_keys(&(&1 == :buffer))
    |> Enum.map(fn {:buffer, {:output, buffer}} -> buffer end)
  end
end

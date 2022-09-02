defmodule Membrane.Scissors do
  @moduledoc """
  Element for cutting the stream.
  """

  use Membrane.Filter
  alias Membrane.Buffer
  alias Membrane.Time

  def_input_pad :input, caps: :any, demand_unit: :buffers
  def_output_pad :output, caps: :any

  def_options intervals: [
                type: :list,
                spec: [{Time.t(), duration :: Time.t() | integer}] | Enumerable.t(),
                description: """
                Enumerable containing `{start_time, duration}` tuples specifying
                parts of the stream that should be preserved. All other parts are
                cut off. Duration unit should conform to the `interval_duration_unit`
                option. Note that infinite streams are also supported.
                """
              ],
              buffer_duration: [
                type: :function,
                spec: (Buffer.t(), caps :: any -> Time.t()),
                description: """
                Function returning the duration of given buffer in Membrane Time units.
                """
              ],
              interval_duration_unit: [
                type: :atom,
                spec: :time | :buffers,
                default: :time,
                description: """
                Unit of the duration of each interval in the `intervals` option.
                If `:buffers` is passed, given amount of buffers is preserved,
                unless the next interval starts earlier. In that case, the stream
                is cut according to the subsequent intervals.
                """
              ],
              filter: [
                type: :function,
                spec: (Buffer.t(), caps :: any -> boolean),
                default: &__MODULE__.always_pass_filter/2,
                description: """
                Function for filtering buffers before they are cut. Each buffer
                is preserved iff it returns `true`. By default always returns `true`.
                """
              ]

  @doc false
  @spec always_pass_filter(Buffer.t(), (any -> boolean)) :: true
  def always_pass_filter(_buffer, _caps), do: true

  @impl true
  def handle_init(opts) do
    %__MODULE__{intervals: intervals} = opts
    {next_intervals, intervals} = StreamSplit.take_and_drop(intervals, 2)

    state =
      opts
      |> Map.from_struct()
      |> Map.merge(%{
        time: 0,
        buffers_count: 0,
        intervals: intervals,
        next_intervals: next_intervals
      })

    {:ok, state}
  end

  @impl true
  def handle_demand(:output, size, :buffers, _ctx, state) do
    {{:ok, demand: {:input, size}}, state}
  end

  @impl true
  def handle_process(:input, buffer, ctx, state) do
    use Ratio
    %{caps: caps} = ctx.pads.input

    {forward?, state} =
      if state.filter.(buffer, caps) do
        forward?(state)
      else
        {false, state}
      end

    actions = if forward?, do: [buffer: {:output, buffer}], else: [redemand: :output]
    state = Map.update!(state, :time, &(&1 + state.buffer_duration.(buffer, caps)))
    {{:ok, actions}, state}
  end

  defp forward?(state) do
    %{
      next_intervals: next_intervals,
      time: time,
      buffers_count: buffers_count,
      interval_duration_unit: interval_duration_unit
    } = state

    cond do
      next_intervals == [] ->
        {false, state}

      time_for_next_interval?(next_intervals, time) ->
        state |> proceed_to_next_interval() |> forward?()

      waiting_for_interval_start?(next_intervals, time) ->
        {false, state}

      within_current_interval?(next_intervals, time, buffers_count, interval_duration_unit) ->
        case interval_duration_unit do
          :time -> {true, state}
          :buffers -> {true, %{state | buffers_count: buffers_count + 1}}
        end

      true ->
        state |> proceed_to_next_interval() |> forward?()
    end
  end

  defp time_for_next_interval?([_interval0, {from, _size} | _], time), do: Ratio.gte?(time, from)
  defp time_for_next_interval?(_next_intervals, _time), do: false

  defp waiting_for_interval_start?([{from, _size} | _], time), do: Ratio.lt?(time, from)
  defp waiting_for_interval_start?(_next_intervals, _time), do: false

  defp within_current_interval?([{from, interval_duration} | _], time, _buffers_count, :time) do
    use Ratio
    Ratio.lt?(time, from + interval_duration)
  end

  defp within_current_interval?([{_from, interval_size} | _], _time, buffers_count, :buffers) do
    buffers_count < interval_size
  end

  defp within_current_interval?(_next_intervals, _time, _buf_cnt, _unit), do: false

  defp proceed_to_next_interval(%{next_intervals: next_intervals, intervals: intervals} = state) do
    {new_next_intervals, intervals} = StreamSplit.take_and_drop(intervals, 1)

    %{
      state
      | next_intervals: tl(next_intervals) ++ new_next_intervals,
        intervals: intervals,
        buffers_count: 0
    }
  end
end

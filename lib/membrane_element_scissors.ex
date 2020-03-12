defmodule Membrane.Element.Scissors do
  @moduledoc """
  Element for cutting off parts of the stream.
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
                cut off. Duration unit should conform to the `duration_unit`
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
              duration_unit: [
                type: :atom,
                spec: :time | :buffers,
                default: :time,
                description: """
                Unit of the duration of each interval in the `intervals` option.
                If `buffers` is passed, given amount of buffers is preserved,
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

    {cut?, state} =
      if state.filter.(buffer, caps) do
        cut(state)
      else
        {true, state}
      end

    actions = if cut?, do: [redemand: :output], else: [buffer: {:output, buffer}]
    state = Map.update!(state, :time, &(&1 + state.buffer_duration.(buffer, caps)))
    {{:ok, actions}, state}
  end

  defp cut(state) do
    %{
      next_intervals: next_intervals,
      time: time,
      buffers_count: buf_cnt,
      duration_unit: duration_unit
    } = state

    cond do
      next_intervals == [] ->
        {true, state}

      time_for_another_cut?(next_intervals, time) ->
        state |> next_cut() |> cut()

      wait_for_current_cut?(next_intervals, time) ->
        {true, state}

      within_current_cut?(next_intervals, time, buf_cnt, duration_unit) ->
        case duration_unit do
          :time -> {false, state}
          :buffers -> {false, %{state | buffers_count: buf_cnt + 1}}
        end

      true ->
        state |> next_cut() |> cut()
    end
  end

  defp time_for_another_cut?([_cut0, {from, _size} | _], time), do: Ratio.gte?(time, from)
  defp time_for_another_cut?(_next_intervals, _time), do: false

  defp wait_for_current_cut?([{from, _size} | _], time), do: Ratio.lt?(time, from)
  defp wait_for_current_cut?(_next_intervals, _time), do: false

  defp within_current_cut?([{from, duration} | _], time, _buf_cnt, :time) do
    use Ratio
    Ratio.lt?(time, from + duration)
  end

  defp within_current_cut?([{_from, cut_cnt} | _], _time, buf_cnt, :buffers) do
    buf_cnt < cut_cnt
  end

  defp within_current_cut?(_next_intervals, _time, _buf_cnt, _unit), do: false

  defp next_cut(%{next_intervals: next_intervals, intervals: intervals} = state) do
    {new_next_intervals, intervals} = StreamSplit.take_and_drop(intervals, 1)

    %{
      state
      | next_intervals: tl(next_intervals) ++ new_next_intervals,
        intervals: intervals,
        buffers_count: 0
    }
  end
end

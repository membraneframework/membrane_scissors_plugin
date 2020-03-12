defmodule Membrane.Element.Scissors do
  use Membrane.Filter

  def_input_pad :input, caps: :any, demand_unit: :buffers
  def_output_pad :output, caps: :any

  def_options filter: [], buffer_duration: [], cuts: [], duration_unit: [default: :time]

  @impl true
  def handle_init(opts) do
    %__MODULE__{cuts: cuts} = opts
    {next_cuts, cuts} = StreamSplit.take_and_drop(cuts, 2)

    state =
      opts
      |> Map.from_struct()
      |> Map.merge(%{time: 0, buffers_count: 0, cuts: cuts, next_cuts: next_cuts})

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
    %{next_cuts: next_cuts, time: time, buffers_count: buf_cnt, duration_unit: duration_unit} =
      state

    cond do
      next_cuts == [] ->
        {true, state}

      time_for_another_cut?(next_cuts, time) ->
        state |> next_cut() |> cut()

      wait_for_current_cut?(next_cuts, time) ->
        {true, state}

      within_current_cut?(next_cuts, time, buf_cnt, duration_unit) ->
        case duration_unit do
          :time -> {false, state}
          :buffers -> {false, %{state | buffers_count: buf_cnt + 1}}
        end

      true ->
        state |> next_cut() |> cut()
    end
  end

  defp time_for_another_cut?([_cut0, {from, _size} | _], time), do: Ratio.gte?(time, from)
  defp time_for_another_cut?(_next_cuts, _time), do: false

  defp wait_for_current_cut?([{from, _size} | _], time), do: Ratio.lt?(time, from)
  defp wait_for_current_cut?(_next_cuts, _time), do: false

  defp within_current_cut?([{from, duration} | _], time, _buf_cnt, :time) do
    use Ratio
    Ratio.lt?(time, from + duration)
  end

  defp within_current_cut?([{_from, cut_cnt} | _], _time, buf_cnt, :buffers) do
    buf_cnt < cut_cnt
  end

  defp within_current_cut?(_next_cuts, _time, _buf_cnt, _unit), do: false

  defp next_cut(%{next_cuts: next_cuts, cuts: cuts} = state) do
    {new_next_cuts, cuts} = StreamSplit.take_and_drop(cuts, 1)
    %{state | next_cuts: tl(next_cuts) ++ new_next_cuts, cuts: cuts, buffers_count: 0}
  end
end

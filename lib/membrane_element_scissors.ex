defmodule Membrane.Element.Scissors do
  use Membrane.Filter

  def_input_pad :input, caps: :any, demand_unit: :buffers
  def_output_pad :output, caps: :any

  def_options filter: [], buffer_duration: [], cuts: []

  @impl true
  def handle_init(opts) do
    %__MODULE__{cuts: cuts} = opts
    {next_cuts, cuts} = StreamSplit.take_and_drop(cuts, 2)

    cuts =
      Stream.map(cuts, fn
        {_from, buffers: _cnt} = cut -> cut
        {from, duration} -> {from, to: from + duration}
      end)

    state =
      opts
      |> Map.from_struct()
      |> Map.merge(%{time: 0, float_time: 0, buffers_count: 0, cuts: cuts, next_cuts: next_cuts})

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
    # FIXME: handle comparing ratios
    state = %{state | float_time: Ratio.to_float(state.time)}
    {{:ok, actions}, state}
  end

  defp cut(%{next_cuts: []} = state) do
    {true, state}
  end

  defp cut(%{next_cuts: [_cut0, {from, _size} | _], float_time: time} = state)
       when time >= from do
    state |> next_cut() |> cut()
  end

  defp cut(%{next_cuts: [{from, _size} | _], float_time: time} = state) when time < from do
    {true, state}
  end

  defp cut(%{next_cuts: [{_from, buffers: cut_cnt} | _], buffers_count: buf_cnt} = state)
       when buf_cnt < cut_cnt do
    {false, %{state | buffers_count: buf_cnt + 1}}
  end

  defp cut(%{next_cuts: [{_from, to: to} | _], time: time} = state)
       when time < to do
    {false, state}
  end

  defp cut(state) do
    state |> next_cut() |> cut()
  end

  defp next_cut(%{next_cuts: next_cuts, cuts: cuts} = state) do
    {new_next_cuts, cuts} = StreamSplit.take_and_drop(cuts, 1)
    %{state | next_cuts: tl(next_cuts) ++ new_next_cuts, cuts: cuts, buffers_count: 0}
  end
end

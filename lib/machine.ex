defmodule Machine do
  import Enum, only: [at: 2, reduce: 3]
  import Bitwise


  @const [
    {:i32_const, &(&1)},
    {:i64_const, &(&1)},
    {:f32_const, &(&1)},
    {:f64_const, &(&1)}
  ]

  @binary [
    {:i32_add,   fn x, y -> Instruction.add(x, y) end},
    {:i32_sub, &(&1-&2)},
    {:i32_mul, &(&1*&2)},
    {:i32_div_s, &div(&1, &2)},
    {:i32_div_u, &div(&1, &2)},
    {:i32_and,   fn x, y -> x &&& y end},
    {:i32_or,    fn x, y -> x ||| y end},
    {:i32_rem_s, fn x, y -> rem(x, y) end},
    {:i32_rem_u, fn x, y -> rem(x, y) end},
    {:i32_eq,    fn x, y -> x == y end},
    {:i32_ne,    fn x, y -> x != y end},
    {:i32_lt_s,  fn x, y -> x < y end},
    {:i32_le_s,  fn x, y -> x <= y end},
    {:i32_gt_s,  fn x, y -> x > y end},
    {:i32_ge_s,  fn x, y -> x >= y end},
    {:i32_lt_u,  fn x, y -> x < y end},
    {:i32_le_u,  fn x, y -> x <= y end},
    {:i32_gt_u,  fn x, y -> x > y end},
    {:i32_ge_u,  fn x, y -> x >= y end},
    {:i32_rotr,  fn x, y -> Instruction.rotr(x, y) end},
    {:i32_rotl,  fn x, y -> Instruction.rotl(x, y) end},
    {:i32_shr_u, fn x, y -> x >>> y end},
    # {:i32_shl,   fn x, y ->}
  ]

  defstruct [
    items: [],
    memory: %{},
    locals: %{},
    functions: []
  ]

  defmodule Function do
    defstruct [
      :nparams,
      :returns,
      :code
    ]
  end

  defmodule ImportFunction do
    defstruct [
      :nparams,
      :returns,
      :call
    ]
  end

  def load(s, addr) do
    s.memory[addr]
  end

  def store(s, addr, val) do
    %{s | memory: Map.put(s.memory, addr, val)}
  end

  def push(s, item = {type, _}) when type in [:i32, :i64, :f32, :f64] do
    %{s | items: [item | s.items]}
  end

  def pop(s) do
    [h|t] = s.items
    {h, %{s | items: t}}
  end

  defp list_to_map(list) do
    list = list |> Enum.with_index()
    for {x, i} <- list, do: {i, x}, into: %{}
  end

  def call(s, %Function{} = func, args) do
    s =
      try do
        execute(%{s | locals: list_to_map(args)}, func.code)
      catch
        :throw, { Return, s} ->
          s
      end
    if func.returns do
      pop(s)
    else
      {nil, s}
    end
  end
  def call(s, %ImportFunction{} = func, args) do
    apply(func.call, args)
    {nil, s}
  end

  # (s, instructions)
  def execute(s, instructions) do
    reduce instructions, s, fn [op|args], s ->
      IO.puts("#{op} #{inspect args} #{inspect s.items}")
      case op do
        :const ->
          push(s, at(args, 0))

        :add ->
          {right, s} = pop(s)
          {left, s} = pop(s)
          push(s, left+right)

        :sub ->
          {right, s} = pop(s)
          {left, s} = pop(s)
          push(s, left-right)

        :mul ->
          {right, s} = pop(s)
          {left, s} = pop(s)
          push(s, left*right)

        :le ->
          {right, s} = pop(s)
          {left, s} = pop(s)
          push(s, left<=right)

        :ge ->
          {right, s} = pop(s)
          {left, s} = pop(s)
          push(s, left>=right)

        :load ->
          {addr, s} = pop(s)
          push(s, load(s, addr))
        :store ->
          {val, s} = pop(s)
          {addr, s} = pop(s)
          store(s, addr, val)

        :local_get ->
          push(s, s.locals[at(args, 0)])

        :local_set ->
          {val, s} = pop(s)
          locals = Map.put(s.locals, at(args, 0), val)
          %{s | locals: locals}

        :call ->
          func = at(s.functions, at(args, 0))
          {fargs, s} = reduce(1..func.nparams, {[], s}, fn _, {fargs, s} ->
            {val, s} = pop(s)
            {[val|fargs], s}
          end)
          {result, s} = call(s, func, fargs)
          if func.returns do
            push(s, result)
          else
            s
          end

        :br ->
          throw {Break, at(args, 0), s}

        :br_if ->
          {val, s} = pop(s)
          if val do
            throw {Break, at(args, 0), s}
          else
            s
          end

        # (:block, [ instructions ])
        :block ->
          try do
            execute(s, at(args, 0))
          catch
            :throw, {Break, level, s} ->
              if level > 0 do
                throw {Break, level - 1, s}
              else
                s
              end
          end
        # if (test) { consequence } else { alternative }
        #
        # [:block, [
        #   [:block, [
        #     test,
        #     [:br_if, 0], # Goto 0
        #     alternative,
        #     [:br, 1],    # Goto 1
        #   ]], # Label: 0
        #   consequence,
        # ] # Label 1

        :loop ->
          do_loop(s, args)

        # while (test) { body }
        # [:block, [
        #   ["loop, [
        #     # Label 0
        #     not test,
        #     [:br_if, 1], #GOTO 1: bread
        #     body,
        #     [:br, 0],
        #   ]]
        # ]]

        :return ->
          throw { Return, s }

        op ->
          raise RuntimeError, "Bad op #{op}"
      end
    end
  end

  defp do_loop(s, args) do
    s = execute(s, at(args, 0))
  catch
    :throw, {Break, level, s} ->
      if level > 0 do
        throw {Break, level - 1, s}
      else
        do_loop(s, args)
      end
  end

  def example() do
    # def update_position(x, v, dt) do
    #   x + v*dt
    # end
    ex_display_player = fn x ->
      IO.puts(String.duplicate(" ", round(x)) <> "<0:>")
      :timer.sleep(20)
    end

    display_player = %ImportFunction{
      nparams: 1,
      returns: false,
      call: ex_display_player
    }

    update_position = %Function{
      nparams: 3,
      returns: true,
      code: [
        [:local_get, 0], # x
        [:local_get, 1], # v
        [:local_get, 2], # dt
        [:mul],
        [:add]
      ]
    }

    functions = [update_position, display_player]
    # x = 2
    # v = 3
    # x = x + v*0.1
    x_addr = 22
    v_addr = 42

    # while x > 0 {
    #   x = update_position(x, v, 0.1)
    #   if x >= 70 {
    #     v = -v
    #   }
    # }
   code = [
      [:block, [
        [:loop, [
            [:const, x_addr],
            [:load],
            [:call, 1],
            [:const, x_addr],
            [:load],
            [:const, 0.0],
            [:le],
            [:br_if, 1],
            [:const, x_addr],
            [:const, x_addr],
            [:load],
            [:const, v_addr],
            [:load],
            [:const, 0.1],
            [:call, 0],
            [:store],
            [:block, [
            [:const, x_addr],
            [:load],
            [:const, 70.0],
            [:ge],
            [:block, [
              [:br_if, 0],
              [:br, 1]
            ]],
            [:const, v_addr],
            [:const, 0.0],
            [:const, v_addr],
            [:load],
            [:sub],
            [:store]
          ]],
          [:br, 0]
        ]]
      ]]
    ]

    s =
      %__MODULE__{functions: functions}
      |> store(x_addr, 2.0)
      |> store(v_addr, 3.0)
      |> execute(code)

    IO.puts "Result: #{load(s, x_addr)}"
  end


end

# Machine.example()
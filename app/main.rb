require_relative 'shadowcasting'

def tick(args)
  grid_w = 16
  grid_h = 16

  args.state.grid ||= [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
  ]

  if args.state.tick_count.zero? # flip grid y-axis
    y = 0
    while y < grid_h >> 1
      x = 0
      while x < grid_w
        i = grid_w * y + x
        j = grid_w * (grid_h - 1 - y) + x
        temp = args.state.grid[i]
        args.state.grid[i] = args.state.grid[j]
        args.state.grid[j] = temp

        x += 1
      end

      y += 1
    end
  end

  args.state.start_x ||= 5
  args.state.start_y ||= 5
  args.state.angle ||= 0

  args.state.last_move ||= 0

  if args.state.last_move < args.state.tick_count - 10
    x = args.inputs.left_right
    y = args.inputs.up_down
    args.state.angle = Math.atan2(y, x).to_degrees unless x.zero? && y.zero?
    args.state.start_x += args.inputs.left_right
    args.state.start_y += args.inputs.up_down
    args.state.last_move = args.state.tick_count
  end

  visible_cone = Array.new(grid_w * grid_h, 0)
  visible_circle = Array.new(grid_w * grid_h, 0)

  start_time = Time.now.to_f
  compute_fov_cone(args.state.grid, grid_w, grid_h, args.state.start_x, args.state.start_y, args.state.angle, 75, 5, visible_cone)
  end_time = (Time.now.to_f - start_time) * 1000.0
  args.outputs.debug << "Cone FOV: #{end_time.round(3)}ms"

  start_time = Time.now.to_f
  compute_fov(args.state.grid, grid_w, grid_h, args.state.start_x, args.state.start_y, 6, visible_circle)
  end_time = (Time.now.to_f - start_time) * 1000.0
  args.outputs.debug << "Circle FOV: #{end_time.round(3)}ms"

  # draw map
  grid_w.times do |y|
    grid_h.times do |x|
      color = args.state.grid[y * grid_w + x] == 1 ? 'sprites/square/blue.png' : 'sprites/square/black.png'
      args.outputs.sprites << {x: x * 32, y: y * 32, w: 32, h: 32, path: color }
    end
  end

  # draw visible tiles
  grid_w.times do |y|
    grid_h.times do |x|
      if visible_cone[y * grid_w + x] == 1
        args.outputs.sprites << {x: x * 32, y: y * 32, w: 32, h: 32, path: 'sprites/square/green.png', a: 100 }
      end
      if visible_circle[y * grid_w + x] == 1
        args.outputs.sprites << {x: x * 32, y: y * 32, w: 32, h: 32, path: 'sprites/square/orange.png', a: 75 }
      end
    end
  end

  args.outputs.sprites << {x: args.state.start_x * 32, y: args.state.start_y * 32, w: 32, h: 32, path: 'sprites/square/red.png' }
end
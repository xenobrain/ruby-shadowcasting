MULT = [
  1, 0, 0, -1, -1, 0, 0, 1,
  0, 1, -1, 0, 0, -1, 1, 0,
  0, 1, 1, 0, 0, -1, -1, 0,
  1, 0, 0, 1, -1, 0, 0, -1
].freeze

def compute_fov(grid, grid_w, grid_h, cx, cy, radius, visible_tiles)
  visible_tiles[cy * grid_w + cx] = 1
  radius2 = radius * radius

  oct = 0
  while oct < 8
    oct_offset = oct
    oct_offset_8 = oct + 8
    oct_offset_16 = oct + 16
    oct_offset_24 = oct + 24

    xx = MULT[oct_offset]
    xy = MULT[oct_offset_8]
    yx = MULT[oct_offset_16]
    yy = MULT[oct_offset_24]

    cast_light(grid, grid_w, grid_h, cx, cy, radius, radius2, visible_tiles,
               xx, xy, yx, yy, 1, 1.0, 0.0)
    oct += 1
  end
end

def cast_light(grid, grid_w, grid_h, cx, cy, radius, radius2, visible_tiles,
               xx, xy, yx, yy, row, start, finish)
  return if start < finish || row > radius

  dy = -row
  dx = -row - 1
  blocked = false
  new_start = 0.0

  dy_plus = dy + 0.5
  dy_minus = dy - 0.5
  inv_dy_plus = 1.0 / dy_plus
  inv_dy_minus = 1.0 / dy_minus

  while dx <= 0
    dx += 1

    l_slope = (dx - 0.5) * inv_dy_plus
    r_slope = (dx + 0.5) * inv_dy_minus

    if start < r_slope
      next
    else
      finish > l_slope ? break : nil
    end

    mx = cx + dx * xx + dy * xy
    my = cy + dx * yx + dy * yy

    if mx < 0 || my < 0 || mx >= grid_w || my >= grid_h
      new_start = r_slope if blocked
      next
    end

    dist2 = dx * dx + dy * dy
    if dist2 >= radius2
      new_start = r_slope if blocked
      next
    end

    idx = my * grid_w + mx
    # Uncomment the line below if you don't want to see walls
    visible_tiles[idx] = 1 # unless grid[idx] == 1

    is_wall = grid[idx] == 1

    if blocked
      if is_wall
        new_start = r_slope
      else
        blocked = false
        start = new_start
      end
    elsif is_wall && row < radius
      blocked = true
      cast_light(grid, grid_w, grid_h, cx, cy, radius, radius2, visible_tiles,
                 xx, xy, yx, yy, row + 1, start, l_slope)
      new_start = r_slope
    end
  end

  unless blocked
    cast_light(grid, grid_w, grid_h, cx, cy, radius, radius2, visible_tiles,
               xx, xy, yx, yy, row + 1, start, finish)
  end
end


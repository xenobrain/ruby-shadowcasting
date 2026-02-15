DEG2RAD = Math::PI / 180.0

MULT = [
  1, 0, 0, -1, -1, 0, 0, 1,
  0, 1, -1, 0, 0, -1, 1, 0,
  0, 1, 1, 0, 0, -1, -1, 0,
  1, 0, 0, 1, -1, 0, 0, -1
].freeze

OCTANT_RANGES = [
  [225.0, 270.0],
  [180.0, 225.0],
  [315.0, 360.0],
  [270.0, 315.0],
  [45.0, 90.0],
  [0.0, 45.0],
  [135.0, 180.0],
  [90.0, 135.0],
].freeze

OCTANT_SLOPE_DIR = [
  [270.0, 225.0],
  [180.0, 225.0],
  [360.0, 315.0],
  [270.0, 315.0],
  [90.0, 45.0],
  [0.0, 45.0],
  [180.0, 135.0],
  [90.0, 135.0],
].freeze

def compute_fov_cone(grid, grid_w, grid_h, cx, cy, direction_deg, width_deg, depth, visible_tiles)
  visible_tiles[cy * grid_w + cx] = 1
  depth2 = depth * depth

  direction_deg = direction_deg % 360.0
  direction_deg += 360.0 if direction_deg < 0

  half_width = width_deg * 0.5
  cone_min = direction_deg - half_width
  cone_max = direction_deg + half_width

  oct = 0
  while oct < 8
    oct_min = OCTANT_RANGES[oct][0]
    oct_max = OCTANT_RANGES[oct][1]

    overlap_min = nil
    overlap_max = nil

    if cone_min < 0.0
      adj_cone_min = cone_min + 360.0
      if oct_max > adj_cone_min
        overlap_min = oct_min >= adj_cone_min ? oct_min : adj_cone_min
        overlap_max = oct_max
      elsif oct_min < cone_max && cone_max > 0
        overlap_min = oct_min
        overlap_max = oct_max <= cone_max ? oct_max : cone_max
      end
    elsif cone_max > 360.0
      adj_cone_max = cone_max - 360.0
      if oct_min < adj_cone_max
        overlap_min = oct_min
        overlap_max = oct_max <= adj_cone_max ? oct_max : adj_cone_max
      elsif oct_max > cone_min
        overlap_min = oct_min >= cone_min ? oct_min : cone_min
        overlap_max = oct_max
      end
    else
      if oct_max > cone_min && oct_min < cone_max
        overlap_min = oct_min >= cone_min ? oct_min : cone_min
        overlap_max = oct_max <= cone_max ? oct_max : cone_max
      end
    end

    if overlap_min && overlap_max && overlap_max > overlap_min
      slope_at_0 = OCTANT_SLOPE_DIR[oct][0]
      slope_at_1 = OCTANT_SLOPE_DIR[oct][1]

      start_slope = angle_to_slope(overlap_min, slope_at_0, slope_at_1)
      finish_slope = angle_to_slope(overlap_max, slope_at_0, slope_at_1)

      if start_slope < finish_slope
        start_slope, finish_slope = finish_slope, start_slope
      end

      if start_slope > finish_slope
        xx = MULT[oct]
        xy = MULT[oct + 8]
        yx = MULT[oct + 16]
        yy = MULT[oct + 24]

        cast_light_cone(grid, grid_w, grid_h, cx, cy, depth, depth2, visible_tiles,
                        xx, xy, yx, yy, 1, start_slope, finish_slope)
      end
    end

    oct += 1
  end
end

def angle_to_slope(angle, slope_at_0, slope_at_1)
  if slope_at_0 < slope_at_1
    range = slope_at_1 - slope_at_0
    slope = (angle - slope_at_0) / range
  else
    range = slope_at_0 - slope_at_1
    slope = (slope_at_0 - angle) / range
  end

  slope = 0.0 if slope < 0.0
  slope = 1.0 if slope > 1.0
  slope
end

def cast_light_cone(grid, grid_w, grid_h, cx, cy, depth, depth2, visible_tiles,
                    xx, xy, yx, yy, row, start, finish)
  return if start < finish || row > depth

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
    if dist2 >= depth2
      new_start = r_slope if blocked
      next
    end

    idx = my * grid_w + mx
    visible_tiles[idx] = 1

    is_wall = grid[idx] == 1

    if blocked
      if is_wall
        new_start = r_slope
      else
        blocked = false
        start = new_start
      end
    elsif is_wall && row < depth
      blocked = true
      cast_light_cone(grid, grid_w, grid_h, cx, cy, depth, depth2, visible_tiles,
                      xx, xy, yx, yy, row + 1, start, l_slope)
      new_start = r_slope
    end
  end

  unless blocked
    cast_light_cone(grid, grid_w, grid_h, cx, cy, depth, depth2, visible_tiles,
                    xx, xy, yx, yy, row + 1, start, finish)
  end
end

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


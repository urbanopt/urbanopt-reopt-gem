def convert_powerflow_resolution(timeseries_kw, original_res, destination_res)
  if timeseries_kw.nil?
    return nil
  end

  if timeseries_kw.empty?
    return nil
  end

  if original_res > destination_res
    # Timesteps will be reduced, i.e. 35040 -> 8760

    # This algorithm works by stepping along the origin timeseries at an interval equal to
    # one timestep in the destintion timeseries and then averaging all origin values that
    # coincide with the interval. Averages are weighted if a destination timestep
    # only partaially overlaps an origin timestep.

    # EX 1
    # stepping interval 2
    # origin stepping       | 1 | 2 | 2 | 4 |
    # destination stepping  |  1.5  |   3   |

    # EX 2
    # stepping interval 2.5
    # origin stepping       | 1 | 1 | 4 | 2 | 2 |
    # destination stepping  |   1.6   |  2.4    |

    result = []
    stepping_interval = Float(original_res) / Float(destination_res)
    current_origin_ts = 0 # fraction stepped along the origin time series
    current_origin_idx = 0 # current integer index of the origin timeseries
    (0..(8760 * destination_res - 1)).each do |ts|
      next_stopping_ts = current_origin_ts + stepping_interval # stop at the next destination interval
      total_power = [] # create to store wieghted origin timestep values to average
      while current_origin_ts != next_stopping_ts
        next_origin_ts_int = Integer(current_origin_ts) + 1
        # Calc next stopping point that will being you to the next origin or destination time step
        next_origin_ts = [next_origin_ts_int, next_stopping_ts].min
        # Calc next step length
        delta_to_next_origin_ts = next_origin_ts - current_origin_ts
        # Add the proportional origin timestep value to the total power variable
        total_power.push(Float(timeseries_kw[current_origin_idx]) * delta_to_next_origin_ts)
        # Only move on to the next origin timestep if you are not ending mid way though an origin timestep
        # i.e  in EX 2 above, the value 4 is needed in destination timestep 1 and 2
        if next_origin_ts_int <= next_stopping_ts
          current_origin_idx += 1
        end
        # Step to the next stopping point
        current_origin_ts += delta_to_next_origin_ts
      end
      # Add averaged total power variable for the destination time step
      result.push(Float(total_power.sum) / stepping_interval)
    end
  end
  if destination_res > original_res
    # Timesteps will be expanded, i.e. 8760 -> 35040

    # This algorithm works by stepping along the destination timeseries. Steps are made to the next
    # destination or origin breakpoint, and at each step the propotional amount of the origin stepped
    # is added to the destination. For example, in in EX 1 below 4 steps are made each with adding the full amount of
    # the origin (1, 1, 2 and 2) since each in the destination overlaps perfectly with 2 origin
    # timesteps. In EX 2, the origin overlaps with the first 2 destination timesteps but the third
    # destination value much be compose of half the 1st origin timestep value and half the second
    # (i.e  4, 4, (4 * 1/2) + (3 * 1/2), 3, and 3 are added to the destination).

    # EX 1
    # stepping interval 2
    # origin stepping       |   1   |   2   |
    # destination stepping  | 1 | 1 | 2 | 2 |

    # EX 2
    # stepping interval 2.5
    # origin stepping       |     4    |    3     |
    # destination stepping  | 4 | 4 | 3.5 | 3 | 3 |

    result = []
    stepping_interval = (Float(destination_res) / Float(original_res))
    current_destination_ts = 0 # fraction stepped along the origin time series
    (0..(8760 * original_res - 1)).each do |original_ts|
      # keep track of step length along the destination time series
      original_indices_stepped = 0
      # See if you are start in the middle of a destination time step and add the proportional
      # value to the most recent (and incomplete) destination value
      remainder = (current_destination_ts - Integer(current_destination_ts))
      if remainder > 0
        current_destination_ts += (1 - remainder)
        original_indices_stepped += (1 - remainder)
        result[-1] = result[-1] + (Float(timeseries_kw[original_ts]) * (1 - remainder))
      end
      # Make whole steps along the destination timeseries that overlap perfectly with the
      # origin timeseries
      while (original_indices_stepped < stepping_interval) && ((original_indices_stepped + 1) <= stepping_interval)
        result.push(Float(timeseries_kw[original_ts]))
        original_indices_stepped += 1
        current_destination_ts += 1
      end
      # See if you need to end your step in the middle of a destination time step and
      # just add the proportional value from the current origin timestep
      remainder = (stepping_interval - original_indices_stepped)
      if remainder > 0
        result.push((Float(timeseries_kw[original_ts]) * remainder))
        current_destination_ts += remainder
      end
    end
  end
  if destination_res == original_res
    # No resolution conversion necessary
    result = timeseries_kw
  end
  return result
end

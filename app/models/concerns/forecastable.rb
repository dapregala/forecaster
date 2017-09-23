#
# Any models that will implement this module should have a `get_total_for_range`
# method that returns any value for a specified time range.
#
module Forecastable extend ActiveSupport::Concern

  included do

    # Returns an array of hashes. There will be 4 hashes, the original data,
    # the moving average, holt, and holt winter forecasts.
    #
    # Attributes of each hash are `name` and `data`. The `name` attribute contains the
    # name of the forecast, it's SMAPE accuracy, and alpha, beta, gamma values used for
    # the forecast (for holt and holt winter), all in a string. The `data` attribute contains
    # time-value pairs.
    #
    # @param start_date
    # @param end_date
    # @param interval
    def get_forecast(start_date, end_date, interval)

      # Initialize variables
      orig_result = Hash.new
      moving_average_result = Hash.new
      holt_result = Hash.new
      holt_winter_result = Hash.new
      start_date = Date.parse start_date
      end_date = Date.parse end_date

      # Initialize SMAPE fitting range for each forecasting method, these
      # ranges are iterated
      ma_smape_fitting_range = [3, 4, 5, 6, 12] # M_points to be tested
      holt_alpha_fitting_range = (0..1).step(0.1)
      holt_beta_fitting_range = (0..1).step(0.1)
      holt_winter_alpha_fitting_range = (0..1).step(0.1)
      holt_winter_beta_fitting_range = (0..1).step(0.1)
      holt_winter_gamma_fitting_range = (0..1).step(0.1)

      # Initialize variables for best smapes, best alphas, betas, and gammas. These are just
      # holder variables for displaying result, not used for computing.
      ma_smape = 0.0
      holt_smape = 0.0
      holt_alpha = 0.0
      holt_beta = 0.0
      holt_winter_smape = 0.0
      holt_winter_alpha = 0.0
      holt_winter_beta = 0.0
      holt_winter_gamma = 0.0

      # Get original data
      orig_result = get_original_data(start_date, end_date, interval)
      orig_x_series = orig_result[:data].keys
      orig_y_series = orig_result[:data].values

      # Initialize X serieses
      moving_average_x = extend_time_x_series(orig_x_series, 1, interval) # Forecast 1 point
      holt_x = extend_time_x_series(orig_x_series, 1, interval) # Forecast 1 point
      holt_winter_x = extend_time_x_series(orig_x_series, 3, interval) # Forecast 12 points


      # Process Moving Average
      moving_average_y = Array.new
      ma_least_smape = 999999999
      # Run tests
      ma_smape_fitting_range.each do | m_point |

        this_test_result = moving_average(orig_y_series, m_point)
        smape_of_this_test = get_smape(orig_y_series, this_test_result)

        # If this smape is the least, set it as the final result
        if smape_of_this_test < ma_least_smape
          ma_least_smape = smape_of_this_test
          moving_average_y = this_test_result
          ma_smape = smape_of_this_test
        end
      end

      # Process Holt
      holt_y = Array.new
      holt_least_smape = 999999999
      # Run tests
      holt_alpha_fitting_range.each do | alpha |
        holt_beta_fitting_range.each do | beta |

          this_test_result = holt(orig_y_series, alpha, beta)
          smape_of_this_test = get_smape(orig_y_series, this_test_result)

          # If this smape is the least, set it as the final result
          if smape_of_this_test < holt_least_smape
            holt_least_smape = smape_of_this_test
            holt_y = this_test_result
            holt_smape = smape_of_this_test
            holt_alpha = alpha.round(2)
            holt_beta = beta.round(2)
          end
        end
      end

      # Process Holt Winter
      holt_winter_y = Array.new
      holt_winter_least_smape = 999999999
      # Run tests
      holt_winter_alpha_fitting_range.each do | alpha |
        holt_winter_beta_fitting_range.each do | beta |
          holt_winter_gamma_fitting_range.each do | gamma |

            this_test_result = holt_winter(orig_y_series, alpha, beta, gamma, 3)
            smape_of_this_test = get_smape(orig_y_series, this_test_result)

            # If this smape is the least, set it as the final result
            if smape_of_this_test < holt_winter_least_smape
              holt_winter_least_smape = smape_of_this_test
              holt_winter_y = this_test_result
              holt_winter_smape = smape_of_this_test
              holt_winter_alpha = alpha.round(2)
              holt_winter_beta = beta.round(2)
              holt_winter_gamma = gamma.round(2)
            end
          end
        end
      end

      # Compile results
      moving_average_result[:data] = collect_x_y(moving_average_x, moving_average_y)
      moving_average_result[:name] = "Moving Average - #{ma_smape}%"
      holt_result[:data] = collect_x_y(holt_x, holt_y)
      holt_result[:name] = "Holt's - #{holt_smape}% (Alpha: #{holt_alpha} Beta: #{holt_beta})"
      holt_winter_result[:data] = collect_x_y(holt_winter_x, holt_winter_y)
      holt_winter_result[:name] = "Holt Winter's - #{holt_winter_smape}% (Alpha: #{holt_winter_alpha} Beta: #{holt_winter_beta} Gamma: #{holt_winter_gamma})"

      [orig_result, moving_average_result, holt_result, holt_winter_result]
    end

    # Gets original data within the range and by interval. Gets data from a data source
    # using `get_total_for_range` method.
    private def get_original_data(start_date, end_date, interval)

      result = Hash.new
      result[:name] = "Original Data"
      result[:data] = Hash.new

      # Initialize loopcounters: start_range_date_counter and end_range_date_counter
      start_range_date_counter = start_date
      if interval == 'day'
        end_range_date_counter = start_date # Make end range exclusive of end_date if counting by day
      else
        end_range_date_counter = start_date + 1.send(interval)
      end

      # Get original data value-time hash
      while end_range_date_counter <= end_date do

        total_for_range = get_total_for_range(start_range_date_counter, end_range_date_counter)

        if total_for_range
          result[:data][start_range_date_counter] = total_for_range
        end

        # Increment counters
        start_range_date_counter += 1.send(interval)
        end_range_date_counter += 1.send(interval)

      end

      result
    end

    # The function that computes moving average forecast based on a series array.
    #
    # @param y_series The original data
    # @param m_point How wide is the moving_average
    #
    # @throws ArgumentError exception if the m_point value is greater than the y series (No first
    # average to compute from)
    #
    # @return The forecast series
    private def moving_average(y_series, m_point)

      if m_point >= y_series.length
        throw ArgumentError.new "M Point moving average should not be greater than the Y series's length."
      end

      result = Array.new
      indices_to_skip = m_point - 1 # Minus one accounts for zero index

      (0..y_series.length).each do |index|

        # Skip first N points (Set as nil because these points are the initial data needed for the first forecast)
        if index <= indices_to_skip
          result[index] = nil
        else

          # Start calculating averages of previous m_points
          sum = 0

          m_point.times do |count|
            sum += y_series[index - count - 1]
          end

          avg = sum/m_point
          result[index] = avg

        end
      end

      result
    end

    # The function that computes holt forecast based on a y_series array
    #
    # @param y_series The original data
    # @param alpha Alpha value to be used
    # @param beta Beta value to be used
    #
    # @return The forecast series
    private def holt(y_series, alpha, beta)

      result = Array.new
      indices_to_skip = 1 - 1 # Minus one accounts for zero index

      # Initial level and trend
      level_t_minus_one = y_series[0]
      trend_t_minus_one = 0

      # Result of this loop has no forecast yet
      (0..y_series.length - 1).each do | index |

        if index <= indices_to_skip
          result[index] = nil
        else

          current_data_point = y_series[index - 1]

          # Calculate current level based on previous value of level (Level t minus one)
          # Also overrides variable current_level
          current_level = (alpha * current_data_point) + ((1 - alpha) * (level_t_minus_one + trend_t_minus_one))

          # Calculate current trend based on previous value of trend (Trend t minus one)
          # Also overrides variable trend_level
          current_trend = (beta * (current_level - level_t_minus_one)) + ((1 - beta) * trend_t_minus_one)

          # Finally, calculate forecast value using current level and current trend
          forecast_value = current_level + current_trend

          # Store in result
          result[index] = forecast_value

          # Override level t minus one and trend t minus one for the next calculations
          level_t_minus_one = current_level
          trend_t_minus_one = current_trend
        end
      end

      # Process forecast
      result[result.length] = level_t_minus_one + trend_t_minus_one

      result
    end

    # The function that computes holt winter forecast based on a y_series array
    #
    # @param series The original data
    # @param alpha Alpha value to be used
    # @param beta Beta value to be used
    # @param gamma Gamma value to be used
    # @param season_length Length of the season
    #
    # @throws ArgumentError exception if actual data series is less than the season
    # length.
    #
    # @return The forecast series
    private def holt_winter(series, alpha, beta, gamma, season_length)

      if season_length >= series.length
        throw ArgumentError.new "Can't process forecast. Season length should be less than the Y series length."
      end

      num_of_seasons = series.size / season_length

      seasonal_indices = get_initial_seasonal_indices(series, season_length, num_of_seasons)

      ft = Array.new(series.length + season_length, nil) # Forecast array

      level = series[0]
      trend = initial_trend(series, season_length)
      seasonality = seasonal_indices[0..(season_length - 1)]

      # Result of this iteration contains no forecast yet:
      ((season_length)..(series.size - 1)).each do |i|

        ft[i] = (level + trend) * seasonality[i - season_length]

        # Update level
        # Multiplicative model
        # new_level = ((alpha * series[i])/(seasonality[i - season_length] == 0 ? 0.000000001: seasonality[i - season_length])) + ((1 - alpha) * (level + trend))
        # Additive model
        new_level = (alpha * (series[i] - seasonality[i - season_length])) + ((1 - alpha) * (level + trend))
        change_in_level = level - new_level

        # Update trend
        new_trend = (beta * change_in_level) + ((1 - beta) * (trend))

        # Update seasonality by adding a value to the seasonality array
        # Multiplicative
        # seasonality[i] = (gamma * (series[i] / (new_level == 0 ? 0.000000001: new_level))) + ((1 - gamma) * seasonality[i - season_length])
        # Additive
        seasonality[i] = (gamma * (series[i] - new_level - trend)) + ((1 - gamma) * seasonality[i - season_length])

        # Use updated level and trend
        level = new_level
        trend = new_trend

      end

      # And now for the forecast
      (series.size..ft.size - 1).each_with_index do |i, index|
        # Multiplicative
        # ft[i] = (level + ((index + 1) * trend)) * ((seasonality[i - season_length]))
        # Additive
        ft[i] = level + ((index + 1) * trend) + (seasonality[i - season_length])
      end

      ft
    end

    # Utility method for Holt Winter. Computes the the initial trend, computes
    # based on the first season data.
    #
    # @param series The original data
    # @param period Length of the season
    private def initial_trend(series, period)
      sum = 0

      (0..period - 1).each do |i|
        sum += (series[period + i] - series[i])
      end

      sum / (period * period)
    end

    # Computes initial seasonal indices
    #
    # @param series The original data
    # @param season_length The length of a season.
    # @param num_of_seasons The number of seasons.
    #
    # @return Array of seasonal indices
    private def get_initial_seasonal_indices(series, season_length, num_of_seasons)

      seasonal_averages = Array.new(num_of_seasons, 0.0)
      seasonal_indices = Array.new(season_length, 0.0) # Initial season index
      averaged_observations = Array.new(series.size, 0.0)

      # Calculate averages of each season
      # Minus one accounts for zero index
      (0..num_of_seasons - 1).each do |i|

        # Calculate summation of current season
        (0..season_length - 1).each do |j|
          seasonal_averages[i] += series[(i * season_length) + j]
        end

        # Calculate average
        seasonal_averages[i] /= season_length
      end

      (0..num_of_seasons - 1).each do |i|
        (0..season_length - 1).each do |j|
          averaged_observations[(i * season_length) + j] = series[(i * season_length) + j] / (seasonal_averages[i] == 0 ? 0.00000000001 : seasonal_averages[i])
        end
      end

      (0..season_length - 1).each do |i|
        (0..num_of_seasons - 1).each do |j|
          seasonal_indices[i] += averaged_observations[(j * season_length) + i]
        end
        seasonal_indices[i] /= num_of_seasons
      end

      seasonal_indices = averaged_observations[0..season_length-1]
    end

    # Computes the SMAPE accuracy of a forecast series against the original series.
    #
    # @param y_actual The original data
    # @param y_forecast The forecast data
    #
    # @return The SMAPE value
    private def get_smape(y_actual, y_forecast)

      individual_smapes = Array.new

      # Get individual smapes first
      y_actual.each_with_index do | actual_value, index |

        # Nil values can occur on the y_forecast, e.g., Moving Average has `nil` forecast for first M_point values
        unless y_forecast[index] == nil
          forecast_value = y_forecast[index]

          divisor = (actual_value.abs + forecast_value.abs)

          if divisor == 0 # If divisor becomes 0, the formula will return an error because it will be dividing by zero
            divisor = 0.00000000001
          end

          result = (forecast_value - actual_value).abs / (divisor / 2)
          individual_smapes << result
        end
      end

      # Get final smape
      smapes_summation = 0
      individual_smapes.each do | smape |
        smapes_summation += smape
      end

      ((smapes_summation / individual_smapes.length) * 100).round(2)
    end

    # Combines two arrays, into a Hash. The first array will be used as keys,
    # and the second array will be used as the corresponding values.
    #
    # @param x_series The array that will be used as keys
    # @param y_series The array that will be used as values
    #
    # @throws ArgumentError exception if the two array lengths are not aligned.
    #
    # @return The Hash result
    private def collect_x_y(x_series, y_series)
      result = Hash.new

      if x_series.length != y_series.length
        throw ArgumentError.new "X Series and Y Series are not aligned"
      else
        length = x_series.length

        length.times do | count |
          result[x_series[count]] = y_series[count]
        end

      end

      result
    end

    # Adds elements to a Date array.
    #
    # @param x_series The array containing Dates. (Should be type Date)
    # @param points_to_add Number of dates to add
    # @param interval Interval of series ("day", "month", "year")
    #
    # @return The extended array
    private def extend_time_x_series(x_series, points_to_add, interval)

      last_date = x_series[x_series.length - 1]

      dates_to_add = Array.new

      points_to_add.times do | count |
        dates_to_add << last_date + (count + 1).send(interval)
      end

      x_series + dates_to_add
    end


  end
end

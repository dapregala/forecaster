# How to use the forecaster

1. Inherit `Forecastable` module on the model you want to have forecasts.
2. Implement `get_total_for_range(start_date, end_date)` function on your model. It must return a value based on the date range requested. For example, range is `06/15/2016` - `07/15/2016`, it should return the sum of all values recorded inside the range.
3. Call the `get_forecast(start_date, end_date, interval)` method on your model. Example: `StockValues.get_by_ticker_symbol("GOOG").get_forecast("06/15/2016", "07/15/2016", "day")`. Interval could be `day`, `month`, and `year`.

## Result
1. The `get_forecast` method should return 4 hashmaps: The original data, moving average, holt, and holt winter.
2. Example of a result is:

```
[
  {
    :name => "Original data"
    :data => {
      "06/15/2016" => "253.43",
      "06/16/2016" => "232.97",
      "06/17/2016" => "247.69",
      ...
    }
  },
  {
    :name => "Moving average (3-pt), SMAPE: 21%",
    "data" => {
      "06/15/2016" => nil,
      "06/16/2016" => nil,
      "06/17/2016" => nil,
      "06/18/2016" => "256.29",
      ...
    }
  },
  {
    :name => "Holt (Alpha: 0.5, Beta: 0.3) SMAPE: 15%",
    "data" => {
      "06/15/2016" => nil,
      "06/16/2016" => "254.25",
      "06/17/2016" => "243.15",
      "06/18/2016" => "256.29",
      ...
    }
  },
  {
    :name => "Holt Winter (Alpha: 0.2, Beta: 0.4, Gamma: 0.1) SMAPE: 18%",
    "data" => {
      "06/15/2016" => nil,
      "06/16/2016" => nil,
      "06/17/2016" => nil,
      "06/18/2016" => "248.95",
      "06/19/2016" => "228.29",
      "06/20/2016" => "243.62",
      ...
    }
  }
]
```

## Configuring forecast specifications

Inside the `Forecastable` module:

### Moving average
1. Configurable via the `ma_smape_fitting_range` property.

### Holt
1. Configurable via the `holt_alpha_fitting_range` and `holt_beta_fitting_range` properties.

### Holt Winter
1. Configurable via the `holt_winter_alpha_fitting_range`, `holt_winter_beta_fitting_range`, and `holt_winter_gamma_fitting_range` properties.
2. Seasonality: The `holt_winter` function has `seasonality` fed in its function.

## Notable forecast functions responsible for the forecasts:

Inside `Forecastable` module:

1. Moving average
```
    # The function that computes moving average forecast based on a series array.
    #
    # @param y_series The original data
    # @param m_point How wide is the moving_average
    #
    # @throws ArgumentError exception if the m_point value is greater than the y series (No first
    # average to compute from)
    #
    # @return The forecast series
    def moving_average(y_series, m_point)
      ...
    end
```

2. Holt
```
    # The function that computes holt forecast based on a y_series array
    #
    # @param y_series The original data
    # @param alpha Alpha value to be used
    # @param beta Beta value to be used
    #
    # @return The forecast series
    def holt(y_series, alpha, beta)
      ...
    end
```

3. Holt Winter
```
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
    def holt_winter(series, alpha, beta, gamma, season_length)
      ...
    end
```
# How to run this app

1. Update `database.yml` to your database credentials
2. Run the following:
```
$ rails db:create
$ rails db:migrate
$ rails db:seed
```
3. Run `$ rails s` and open `http://localhost:3000`

# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

class Stock < ApplicationRecord

  has_many :stock_values
  include Forecastable

  def get_total_for_range(start_date, end_date)
    stock_values = StockValue.where(:stock_id => id, :date => start_date..end_date)
    sum = nil

    unless stock_values.empty?
      sum = stock_values.sum(:value)
    end

    sum
  end

end

class StocksController < ApplicationController

	def index
		@my_array = Stock.find_by_ticker_symbol("DD").get_forecast('1/1/2015', '1/1/2017', "month")
	end
end

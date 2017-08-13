require "csv"

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Import stock quotes for the year 2016
Stock.delete_all
in_stock_quotes_dir = Rails.root.join('lib', 'seeds', 'stocks');
desired_quotes = ["DD"]
Dir.foreach(in_stock_quotes_dir) do |item|

	# Exlude . and .. entries
	next if item == '.' or item == '..'
	puts "Importing #{item}"

	# Open file
	csv_file = File.read("#{in_stock_quotes_dir}/#{item}");
	csv = CSV.parse(csv_file, :headers => false)
	
	csv.each do |row|

		# Read desired value only
		next unless desired_quotes.include?(row[0])

    stock = Stock.find_by_ticker_symbol(row[0])

    unless stock
      stock = Stock.new
      stock.ticker_symbol = row[0]
    end

    stock_value = StockValue.new
		stock_value.date = Date.strptime(item[12..19], "%m%d%Y") # Substring the date from the file because date sometimes is null in the CSV
		stock_value.value = row[2]

    stock.stock_values << stock_value
		stock.save

	end

end
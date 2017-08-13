class CreateStocks < ActiveRecord::Migration[5.1]
  def change
    create_table :stocks do |t|
      t.string :ticker_symbol

      # Moved to stockvalue model
      # t.decimal :value, :precision => 16, :scale => 2
      # t.date :date

      t.timestamps
    end
  end
end

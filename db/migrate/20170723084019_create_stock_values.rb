class CreateStockValues < ActiveRecord::Migration[5.1]
  def change
    create_table :stock_values do |t|

      t.references :stock
      t.decimal :value, :precision => 16, :scale => 2
      t.date :date

      t.timestamps
    end
  end
end

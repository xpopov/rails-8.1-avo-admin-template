class CreateBasicCrm < ActiveRecord::Migration[8.1]
  def change
    rename_table :accounts, :users
    add_column :users, :name, :string

    create_table :customers do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.text :notes
      t.timestamps
    end

    create_table :addresses do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :label
      t.string :line1, null: false
      t.string :line2
      t.string :city, null: false
      t.string :region
      t.string :postal_code
      t.string :country_code, null: false
      t.timestamps
    end

    create_table :products do |t|
      t.string :name, null: false
      t.string :sku, null: false
      t.text :description
      t.decimal :unit_price, precision: 12, scale: 2, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :products, :sku, unique: true
    add_check_constraint :products, "unit_price >= 0", name: "products_nonnegative_price"

    create_table :sales_orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :status, default: "draft", null: false
      t.date :ordered_on, null: false
      t.text :notes
      t.timestamps
    end
    add_check_constraint :sales_orders, "status IN ('draft', 'confirmed', 'completed', 'cancelled')", name: "sales_orders_valid_status"

    create_table :sales_order_items do |t|
      t.references :sales_order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, default: 1, null: false
      t.decimal :unit_price, precision: 12, scale: 2, null: false
      t.timestamps
    end
    add_check_constraint :sales_order_items, "quantity > 0", name: "sales_order_items_positive_quantity"
    add_check_constraint :sales_order_items, "unit_price >= 0", name: "sales_order_items_nonnegative_price"
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_23_001000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  create_table "account_login_change_keys", force: :cascade do |t|
    t.string "key", null: false
    t.string "login", null: false
    t.datetime "deadline", null: false
  end

  create_table "account_password_reset_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "account_remember_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
  end

  create_table "account_verification_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "requested_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "addresses", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "label"
    t.string "line1", null: false
    t.string "line2"
    t.string "city", null: false
    t.string "region"
    t.string "postal_code"
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_addresses_on_customer_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.string "phone"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "log_entries", force: :cascade do |t|
    t.text "message", null: false
    t.integer "type", null: false
    t.string "section"
    t.string "tags"
    t.string "exception_class"
    t.jsonb "details", default: {}, null: false
    t.integer "severity"
    t.datetime "notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section"], name: "index_log_entries_on_section"
    t.index ["severity"], name: "index_log_entries_on_severity"
    t.index ["type"], name: "index_log_entries_on_type"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "sku", null: false
    t.text "description"
    t.decimal "unit_price", precision: 12, scale: 2, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.check_constraint "unit_price >= 0::numeric", name: "products_nonnegative_price"
  end

  create_table "sales_order_items", force: :cascade do |t|
    t.bigint "sales_order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_sales_order_items_on_product_id"
    t.index ["sales_order_id"], name: "index_sales_order_items_on_sales_order_id"
    t.check_constraint "quantity > 0", name: "sales_order_items_positive_quantity"
    t.check_constraint "unit_price >= 0::numeric", name: "sales_order_items_nonnegative_price"
  end

  create_table "sales_orders", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "status", default: "draft", null: false
    t.date "ordered_on", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_sales_orders_on_customer_id"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'confirmed'::character varying::text, 'completed'::character varying::text, 'cancelled'::character varying::text])", name: "sales_orders_valid_status"
  end

  create_table "users", force: :cascade do |t|
    t.integer "status", default: 1, null: false
    t.citext "email", null: false
    t.string "password_hash"
    t.boolean "admin", default: false, null: false
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(status = ANY (ARRAY[1, 2]))"
    t.check_constraint "email = 'admin'::citext OR email ~ '^[^,;@ \r\n]+@[^,@; \r\n]+[.][^,@; \r\n]+$'::citext", name: "valid_email"
  end

  add_foreign_key "account_login_change_keys", "users", column: "id"
  add_foreign_key "account_password_reset_keys", "users", column: "id"
  add_foreign_key "account_remember_keys", "users", column: "id"
  add_foreign_key "account_verification_keys", "users", column: "id"
  add_foreign_key "addresses", "customers"
  add_foreign_key "sales_order_items", "products"
  add_foreign_key "sales_order_items", "sales_orders"
  add_foreign_key "sales_orders", "customers"
end

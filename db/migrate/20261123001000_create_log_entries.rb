class CreateLogEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :log_entries do |t|
      t.text :message, null: false
      t.integer :type, null: false, index: true
      t.string :section, index: true
      t.string :tags
      t.string :exception_class
      t.jsonb :details, null: false, default: {}
      t.integer :severity, index: true
      t.datetime :notified_at

      t.timestamps
    end
  end
end

class AllowAdminLogin < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :accounts, name: "valid_email"
    add_check_constraint :accounts,
      "email = 'admin' OR email ~ '^[^,;@ \r\n]+@[^,@; \r\n]+[.][^,@; \r\n]+$'",
      name: "valid_email"
  end

  def down
    remove_check_constraint :accounts, name: "valid_email"
    add_check_constraint :accounts,
      "email ~ '^[^,;@ \r\n]+@[^,@; \r\n]+[.][^,@; \r\n]+$'",
      name: "valid_email"
  end
end

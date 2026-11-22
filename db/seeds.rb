Account.find_or_create_by!(email: "admin") do |account|
  account.status = :verified
  account.admin = true
  account.password = "admin"
end

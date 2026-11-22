User.find_or_create_by!(email: "admin") do |account|
  account.status = :verified
  account.admin = true
  password = ENV.fetch("ADMIN_PASSWORD") do
    raise "Set ADMIN_PASSWORD before seeding production" if Rails.env.production?
    "admin"
  end
  account.password_hash = BCrypt::Password.create(password)
end

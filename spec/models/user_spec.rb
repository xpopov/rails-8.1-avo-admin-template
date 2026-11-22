require "rails_helper"

RSpec.describe User, type: :model do
  it "builds an isolated ordinary user without writing to the database" do
    expect { @user = build(:user) }.not_to change(User, :count)
    expect(@user).not_to be_admin
    expect(@user).to be_verified
    expect(@user).to be_valid
    expect(@user.password_hash).not_to eq(@user.password)
  end

  it "has explicit administrator and active scopes" do
    admin = create(:user, :admin)
    closed = create(:user, :closed)
    expect(User.administrators).to include(admin)
    expect(User.active).not_to include(closed)
  end

  it "requires an email, a valid new password and a unique active login" do
    user = create(:user)
    expect(build(:user, email: user.email.upcase)).not_to be_valid
    expect(build(:user, email: "invalid")).not_to be_valid
    expect(build(:user, password: "short")).not_to be_valid
  end

  it "keeps the password hash when a form submits a blank password" do
    user = create(:user)
    expect { user.update!(password: "", name: "Renamed") }.not_to change { user.reload.password_hash }
  end
end

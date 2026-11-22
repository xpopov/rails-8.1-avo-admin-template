RSpec.shared_examples "a CRM resource" do |path|
  it "redirects guests to login" do
    get path
    expect(response).to redirect_to("/login")
  end

  it "allows regular verified users" do
    sign_in_user
    get path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('href="/resources/users"')
  end

  it "allows administrators" do
    sign_in_user(create(:user, :admin))
    get path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('href="/resources/users"')
  end
end

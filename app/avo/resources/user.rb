class Avo::Resources::User < Avo::BaseResource
  self.title = :email

  def self.visible_on_sidebar
    Avo::Current.user&.admin?
  end

  def fields
    field :id, as: :id
    field :name, as: :text
    field :email, as: :text, required: true
    field :password, as: :password, help: "At least 8 characters. Leave blank to keep the current password."
    field :status, as: :select, enum: ::User.statuses, default: "verified", required: true
    field :admin, as: :boolean
  end
end

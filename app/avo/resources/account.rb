class Avo::Resources::Account < Avo::BaseResource
  self.title = :email

  def fields
    field :id, as: :id
    field :email, as: :text, required: true
    field :status, as: :select, enum: ::Account.statuses
    field :admin, as: :boolean
  end
end

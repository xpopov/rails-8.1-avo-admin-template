class Avo::Resources::Customer < Avo::BaseResource
  self.title = :name

  def fields
    field :id, as: :id
    field :name, as: :text, required: true
    field :email, as: :text
    field :phone, as: :text
    field :notes, as: :textarea
    field :addresses, as: :has_many
    field :sales_orders, as: :has_many
  end
end

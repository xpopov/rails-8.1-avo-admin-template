class Avo::Resources::Product < Avo::BaseResource
  self.title = :name

  def fields
    field :id, as: :id
    field :name, as: :text, required: true
    field :sku, as: :text, required: true
    field :description, as: :textarea
    field :unit_price, as: :number, min: 0, step: 0.01, required: true
    field :active, as: :boolean
  end
end

class Avo::Resources::SalesOrderItem < Avo::BaseResource
  self.title = :display_name
  self.visible_on_sidebar = false

  def fields
    field :id, as: :id
    field :sales_order, as: :belongs_to, required: true
    field :product, as: :belongs_to, required: true
    field :quantity, as: :number, min: 1, step: 1, required: true
    field :unit_price, as: :number, min: 0, step: 0.01, help: "Defaults to the product price when first saved."
    field :subtotal, as: :number, readonly: true, only_on: [ :index, :show ]
  end
end

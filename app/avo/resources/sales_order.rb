class Avo::Resources::SalesOrder < Avo::BaseResource
  self.title = :display_name

  def fields
    field :id, as: :id
    field :customer, as: :belongs_to, required: true
    field :status, as: :select, enum: ::SalesOrder.statuses, required: true
    field :ordered_on, as: :date, required: true
    field :notes, as: :textarea
    field :total, as: :number, readonly: true, only_on: [ :index, :show ]
    field :sales_order_items, as: :has_many
  end
end

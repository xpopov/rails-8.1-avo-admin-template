class Avo::Resources::SalesOrder < Avo::BaseResource
  self.title = :display_name

  def fields
    tabs id: :sales_order do
      tab title: "Details" do
        index_fields
      end

      field :sales_order_items, as: :has_many, name: "Order items", show_on: :edit
    end
  end

  def index_fields
    field :id, as: :id
    field :customer, as: :belongs_to, required: true
    field :status, as: :select, enum: ::SalesOrder.statuses, required: true
    field :ordered_on, as: :date, required: true
    field :notes, as: :textarea
    field :total, as: :number, readonly: true, only_on: [ :index, :show ]
  end
end

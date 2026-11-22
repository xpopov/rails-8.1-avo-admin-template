class Avo::Resources::Customer < Avo::BaseResource
  self.title = :name

  def fields
    tabs id: :customer do
      tab title: "Details" do
        index_fields
      end

      field :addresses, as: :has_many, show_on: :edit
      field :sales_orders, as: :has_many, show_on: :edit
    end
  end

  def index_fields
    field :id, as: :id
    field :name, as: :text, required: true
    field :email, as: :text
    field :phone, as: :text
    field :notes, as: :textarea
  end
end

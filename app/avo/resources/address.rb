class Avo::Resources::Address < Avo::BaseResource
  self.title = :display_name
  self.visible_on_sidebar = false

  def fields
    field :id, as: :id
    field :customer, as: :belongs_to, required: true
    field :label, as: :text
    field :line1, as: :text, required: true
    field :line2, as: :text
    field :city, as: :text, required: true
    field :region, as: :text
    field :postal_code, as: :text
    field :country_code, as: :text, required: true, help: "Two-letter code, e.g. US."
  end
end

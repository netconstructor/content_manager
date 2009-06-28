class Components::<%= class_name %> < Content::Item
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>
end

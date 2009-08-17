class Components::<%= class_name %> < Content::Item
<% attributes.select(&:reference?).each do |attribute| -%>
  field :<%= attribute.name %>
<% end -%>
end

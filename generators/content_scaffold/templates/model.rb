class Content::<%= class_name %> < Content::Item
<% for attribute in attributes -%>
  field :<%= attribute.name %>
<% end -%>
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>
end

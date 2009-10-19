module Content
  module Solr
    class SearchResult
      attr_accessor :attributes

      def initialize(attributes)
        @attributes = attributes.symbolize_keys
      end
  
      def id
        @attributes[:id]
      end

      def item
        @item ||= Content::Item.find_by_id id.to_i
      end

      def method_missing(name)
        @attributes[name]
      end
    end
  end
end

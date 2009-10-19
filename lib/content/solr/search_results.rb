module Content
  module Solr
    class SearchResults
      attr_accessor :start, :count, :docs, :facets, :spelling
  
      def initialize(attributes, page, per_page)
        @start = attributes["response"]["start"]
        @count = attributes["response"]["numFound"]
        @docs = WillPaginate::Collection.create(page, per_page, @count) do |pager|
          pager.replace(attributes["response"]["docs"].collect {|item| SearchResult.new(item) })
        end
        @facets = attributes["facet_counts"].symbolize_keys unless attributes["facet_counts"].nil?
        unless @facets.nil?
          unless @facets[:facet_fields].nil?
            @facets[:facet_fields].keys.each do |k|
              @facets[:facet_fields][k.gsub("_s", "").to_sym] = Hash[*@facets[:facet_fields].delete(k)]
            end
          end
        end
        unless attributes["spellcheck"].nil?
          @spelling = Hash[*attributes["spellcheck"]["suggestions"]]
        else
          @spelling = {}
        end
        if attributes["highlighting"]
          @docs.each do |doc|
            attributes["highlighting"][doc.id].each_pair do |k,v|
              doc.attributes[k.to_sym] = v.first
            end
          end
        end
      end
    end
  end
end

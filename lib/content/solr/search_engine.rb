module Content
  module Solr
    class SearchEngine
      def self.solr
        @solr_options ||= ::YAML::load_file("#{RAILS_ROOT}/config/solr.yml")[::RAILS_ENV.to_s].symbolize_keys
        ::RSolr.connect(:url => "http://#{@solr_options[:host] || 'localhost'}" + ":#{@solr_options[:port] || 8983}" + "#{@solr_options[:path] || '/'}")
      end

      def self.search(options)
        page = (options.delete(:page) || 1).to_i
        per_page = (options[:per_page] || 30).to_i
        options[:start] = (page - 1) * per_page
        options[:rows] ||= options.delete(:per_page)
        options[:spellcheck] = "on"
        if options.has_key? "facet.field"
          options[:facet] = true
          options["facet.field"] = options["facet.field"].split(",").collect {|item| item.strip}
          options["facet.mincount"] = 1
        end
        SearchResults.new(self.solr.select(options), page, per_page)
      end

      def self.add(item)
        values = {:id => item.id}.merge((item.searchable_fields | item.class.facet_attributes).inject({}) {|h, k| h[k.to_sym] = item.send(k.to_sym) rescue nil; h })
        values.keys.each do |k|
          if values[k].is_a?(Date) or values[k].is_a?(Time)
            if k == :updated_at or k == :created_at
              values[k] = values[k].iso8601
            else
              values["#{k}_dt".to_sym] = values.delete(k).iso8601
            end
          elsif values[k].is_a?(Array)
            values["#{k}_s".to_sym] = values[k].join(",")
            values["#{k}_facet".to_sym] = values.delete k
            values.delete k
          elsif values[k].is_a?(Hash)
            values.delete k
          elsif values[k].is_a?(String)
            values["#{k}_s".to_sym] = values[k] if ![:version, :content_type].include?(k)
          elsif values[k].is_a?(Fixnum)
            values["#{k}_i".to_sym] = values.delete k if k != :id
          elsif values[k].is_a?(Float)
            values["#{k}_f".to_sym] = values.delete k
          else
            values.delete k
          end
        end
        values.keys.each {|k| values.delete(k) unless values[k] }
        values[:section_s] = item.parent.heading unless item.parent.nil?
        values[("random" + item.version).to_sym] = item.version
        values[:text] = item.pages.collect(&:body).join("\n") unless item.pages.nil?
        values[:tags] = item.tags
        begin
#          pp values
          self.solr.add(values)
          item.indexed_version = item.version
          item.unversioned_update!
       rescue
          puts "ERROR INDEXING!!!!!!!!!!!!"
          pp values
        end
      end

      def self.delete_by_query(query)
        self.solr.delete_by_query(query)
      end

      def self.delete_by_id(id)
        self.solr.delete_by_id(id)
      end

      def self.commit
        self.solr.commit
      end

      def self.optimize
        self.solr.optimize
      end
    end
  end
end

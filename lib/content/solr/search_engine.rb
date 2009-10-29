module Content
  module Solr
    class SearchEngine
      def self.get_connection(which = :reader)
        @connections ||= begin
          connections = {}
          connections[:writer] = []
          connections[:reader] = []

          [::YAML::load_file("#{RAILS_ROOT}/config/content_solr.yml")[::RAILS_ENV.to_s]].flatten.each do |opts|
            opts.symbolize_keys!

            if opts.has_key?(:writer)
              [opts[:writer]].flatten.each do |conn|
                connections[:writer] << create_connection(conn.symbolize_keys)
              end
            end

            if opts.has_key?(:reader)
              [opts[:reader]].flatten.each do |conn|
                connections[:reader] << create_connection(conn.symbolize_keys)
              end
            end

            unless opts.has_key?(:writer) or opts.has_key?(:reader)
              connection = create_connection(opts)
              connections[:writer] << connection
              connections[:reader] << connection
            end
          end

          connections[:writer].each do |conn|
            logger.debug "Content Solr Writer: #{conn}"
          end

          connections[:reader].each do |conn|
            logger.debug "Content Solr Reader: #{conn}"
          end
          
          connections
        end

        url = @connections[which].rand
        logger.debug "Solr chose #{url}"
        ::RSolr.connect(:url => url)
      end
      
      def self.create_connection(options)
        "http://#{options[:host] || 'localhost'}" + ":#{options[:port] || 8983}" + "#{options[:path] || '/'}"
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
        SearchResults.new(self.get_connection.select(options), page, per_page)
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
        values[:human_name] = item.class.human_name
        values[:random_i] = (Kernel.rand * 10000).to_i
        values[:text] = item.pages.collect(&:body).join("\n") unless item.pages.nil?
        values[:tags] = item.tags
        begin
#          pp values
          self.get_connection(:writer).add(values)
          item.indexed_version = item.version
          item.unversioned_update!
       rescue
          puts "ERROR INDEXING!!!!!!!!!!!!"
          pp values
        end
      end

      def self.delete_by_query(query)
        self.get_connection(:writer).delete_by_query(query)
      end

      def self.delete_by_id(id)
        self.get_connection(:writer).delete_by_id(id)
      end

      def self.commit
        self.get_connection(:writer).commit
      end

      def self.optimize
        self.get_connection(:writer).optimize
      end
      
      def self.logger
        ActiveRecord::Base.logger
      end
    end
  end
end

module Content
  module Solr
    module ClassMethods
      def auto_index
        Content::Item.send :include, Content::Solr::InstanceMethods
      end

      def destroy_index!
        SearchEngine.delete_by_query "content_type:#{self.name.gsub('::', '\:\:')}"
        SearchEngine.commit
      end

      def build_index!(force = false)
        conditions = {:status => :published}
        how_many = self.count(:conditions => conditions, :limit => 10000000)
        offset, increment, indexed, skipped = 0, 1000, 0, 0

        puts "Indexing #{self.name} (#{how_many} items):"

        while offset < how_many
          indexed_in_increment = 0
          
          self.all(:conditions => conditions, :offset => offset, :limit => increment, :order => "version desc").each do |item|
            if item.searchable? and !item.url.blank?
              if force || item.indexed_version != item.version
                puts "  #{item.id} (#{item.content_type}) - #{item.url}"
                SearchEngine.add item
                indexed_in_increment += 1
                indexed += 1
              else
                skipped += 1
              end
            end
          end
          
          if indexed_in_increment > 0
            puts "Committing"
            SearchEngine.commit
          end

          offset += increment
        end
        
        puts "Finished indexing"
        puts "Added   : #{indexed}"
        puts "Skipped : #{skipped}"
      end

      def rebuild_index!
        build_index! true
      end

      def search(options)
        options[:fq] ||= ""
        options[:fq] = options[:fq] + " content_type:#{self.name.gsub('::', '\:\:')}" unless self.name == "Content::Item"
        options[:fq].strip!
        Content::Solr::SearchEngine.search(options)
      end
    end
  end
end

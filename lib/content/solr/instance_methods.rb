module Content
  module Solr
    module InstanceMethods
      def self.included(base)
        base.alias_method_chain :perform_save, :solr
        base.alias_method_chain :destroy, :solr
      end

      def perform_save_with_solr(*args) #:nodoc:
        if status = perform_save_without_solr(*args)
          SearchEngine.add(self)
        end
        status
      end

      def destroy_with_solr #:nodoc:
        if status = destroy_without_solr(*args)
          SearchEngine.delete_by_id id
        end
        status
      end
    end
  end
end

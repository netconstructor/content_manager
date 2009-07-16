require 'rufus/tokyo'

module Content
  module Adapters
    class CabinetAdapter < Base
      def initialize(options = {})
        file = options[:database] || options["database"] || "db/content.tct"
        mode = options[:mode] || options["mode"] || "create"
        @connection = Rufus::Tokyo::Table.new(file, mode)
      end

      def prepare_query(klass, query_options)
      end
      
      def run_query(klass, query_options)
        results = nil
        ms = Benchmark.ms do
          query_options[:limit] ||= 1000
          results = @connection.query { |q|
            (query_options[:conditions] || {}).each { |cond| 
              if cond[1].is_a? Hash
                q.condition(key, cond[1].keys.first, cond[1].values.first) 
              else
                q.add_condition cond[0], :eq, cond[1]
              end
            }
            (query_options[:order] || []).each {|order| q.order_by order }
          }.collect {|r| r.symbolize_keys }
        end
        log_select(query_options, klass, ms)
        results
      end

      def count(klass, query_options)
        run_query(klass, query_options).length
      end
      
      def get_record_by_id(klass, id)
        record = nil
        ms = Benchmark.ms do
          record = @connection[id.to_s].symbolize_keys
        end
        log_select({:conditions => {:__id => id, :content_type => klass.name.to_s}}, klass, ms)
        record
      end

      def save_record(klass, id, attributes)
        ms = Benchmark.ms do
          @connection[id.to_s] = attributes.stringify_keys
        end
        log_update(id, attributes, klass, ms)
        true
      end

      def delete_record_by_id(klass, id)
        ms = Benchmark.ms do
          @connection.delete id
        end
        log_delete(id, klass, ms)
        true
      end

      def genuid
        @connection.genuid
      end
    end
  end
end

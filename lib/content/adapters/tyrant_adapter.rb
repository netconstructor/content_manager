require 'tokyo_tyrant'

module Content
  module Adapters
    class TyrantAdapter < Base
      def initialize(options = {})
        host = options[:host] || options["host"] || "localhost"
        port = options[:port] || options["port"] || 1978
        @connection = TokyoTyrant::Table.new(host, port)
        @logger = ActiveRecord::Base.logger
      end

      def prepare_query(klass, query_options)
        query_options[:limit] ||= 1000
        query_options[:offset] || -1
        returning @connection.query do |q|
          (query_options[:conditions] || {}).each { |key, value| 
            if value.is_a? Hash
              q.condition(key, value.keys.first, value.values.first) 
            else
              q.condition(key, :streq, value) 
            end
          }
          (query_options[:order] || []).each { |order| q.order_by(order, :strasc) }
          q.limit(query_options[:limit], query_options[:offset])
        end
      end
      
      # :streq - for string which is equal to the expression
      # :strinc - for string which is included in the expression
      # :strbw - for string which begins with the expression
      # :strew - for string which ends with the expression
      # :strand - for string which includes all tokens in the expression
      # :stror - for string which includes at least one token in the expression
      # :stroreq - for string which is equal to at least one token in the expression
      # :strrx - for string which matches regular expressions of the expression
      # :numeq - for number which is equal to the expression
      # :numgt - for number which is greater than the expression
      # :numge - for number which is greater than or equal to the expression
      # :numlt - for number which is less than the expression
      # :numle - for number which is less than or equal to the expression
      # :numbt - for number which is between two tokens of the expression
      # :numoreq - for number which is equal to at least one token in the expression
      # :ftsph - for full-text search with the phrase of the expression
      # :ftsand - for full-text search with all tokens in the expression
      # :ftsor - for full-text search with at least one token in the expression
      # :ftsex - for full-text search with the compound expression. 

      def run_query(klass, query_options)
        results = nil
        ms = Benchmark.ms do
          query = prepare_query klass, query_options
          results = query.get
        end
        log_select(query_options, klass, ms)
        results
      end

      def count(klass, query_options)
        results = nil
        ms = Benchmark.ms do
          query = prepare_query klass, query_options
          results = query.searchcount
        end
        log_count(query_options, klass, ms)
        results
      end

      def get_record_by_id(klass, id)
        record = nil
        ms = Benchmark.ms do
          record = @connection[id]
        end
        log_select({:conditions => {:__id => id, :content_type => klass.name.to_s}}, klass, ms)
        record
      end

      def save_record(klass, id, attributes)
        ms = Benchmark.ms do
          @connection[id] = attributes
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

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
          (query_options[:conditions] || {}).each { |key, value| q.condition(key, :streq, value) }
          (query_options[:order] || []).each { |order| q.order_by(order, :strasc) }
          q.limit(query_options[:limit], query_options[:offset])
        end
      end

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
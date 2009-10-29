require 'tokyo_tyrant'

module Content
  module Adapters
    class TyrantAdapter < Base
      def initialize(options = {})
        @connections = {}
        @connections[:writer] = []
        @connections[:reader] = []

        [options].flatten.each do |opts|
          opts.symbolize_keys!

          if opts.has_key?(:writer)
            [opts[:writer]].flatten.each do |conn|
              @connections[:writer] << create_connection(conn.symbolize_keys)
            end
          end

          if opts.has_key?(:reader)
            [opts[:reader]].flatten.each do |conn|
              @connections[:reader] << create_connection(conn.symbolize_keys)
            end
          end

          unless opts.has_key?(:writer) or opts.has_key?(:reader)
            connection = create_connection(opts)
            @connections[:writer] << connection
            @connections[:reader] << connection
          end
        end
        
        @connections[:writer].each do |conn|
          logger.debug "Tyrant Writer: #{conn.server}"
        end
        
        @connections[:reader].each do |conn|
          logger.debug "Tyrant Reader: #{conn.server}"
        end
      end

      def prepare_query(klass, query_options)
        query_options[:limit] ||= 1000
        query_options[:offset] ||= -1
        returning get_connection.query do |q|
          (query_options[:conditions] || {}).each { |key, value| 
            key = :__id if key == :id
            if value.is_a? Hash
              q.condition(key, value.keys.first, value.values.first) 
            else
              q.condition(key, :streq, value) 
            end
          }
          unless query_options[:order].nil?
            order = query_options[:order]
            raise "Cannot sort by multiple columns" unless order.is_a?(String) or order.is_a?(Symbol)
            raise "Cannot sort by multiple columns" if order.to_s.split(",").length > 1
            direction = :strasc
            field = order.to_s.strip
            if field =~ /(ASC|DESC)$/i
              direction = "str#{$1.downcase}".to_sym
              field.gsub!(/\s*(ASC|DESC)?$/i, '')
            end
            q.order_by(field.to_sym, direction)
          end
          q.limit(query_options[:limit], query_options[:offset])
        end
      end
      
      def run_query(klass, query_options)
        results = nil
        ms = Benchmark.ms do
          query = prepare_query klass, query_options
          results = query.get
        end
        log_select(query_options, klass, "*", ms)
        results
      end

      def run_query_for_ids(klass, query_options)
        results = nil
        ms = Benchmark.ms do
          query = prepare_query klass, query_options
          results = query.search.collect(&:to_i)
        end
        log_select(query_options, klass, "id", ms)
        results
      end

      def mget(klass, ids)
        if ids.length > 0
          results = nil
          ms = Benchmark.ms do
            results = get_connection.mget ids
          end
          log_select({:conditions => {:id => ids}}, klass, "*", ms)
          ids.collect {|id| results[id.to_s] }
        else
          []
        end
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
          record = get_connection[id]
        end
        log_select({:conditions => {:__id => id, :content_type => klass.name.to_s}}, klass, "*", ms)
        record
      end

      def save_record(klass, id, attributes)
        ms = Benchmark.ms do
          get_connection(:writer)[id] = attributes
        end
        log_update(id, attributes, klass, ms)
        true
      end

      def delete_record_by_id(klass, id)
        ms = Benchmark.ms do
          get_connection(:writer).delete id
        end
        log_delete(id, klass, ms)
        true
      end

      def genuid
        get_connection(:writer).genuid
      end

      def get_connection(which = :reader)
        @connections[which].rand
      end

      def create_connection(conn)
        host = conn[:host] || "localhost"
        port = conn[:port] || 1978
        timeout = (conn[:timeout] || 15).to_f
        reconnect = conn[:retry] || true
        TokyoTyrant::Table.new(host, port, timeout, reconnect)
      end

      def logger
        ActiveRecord::Base.logger       
      end
      
    end
  end
end

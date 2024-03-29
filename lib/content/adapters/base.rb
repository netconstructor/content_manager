module Content
  module Adapters
    class Base
      @@row_even = true
    protected
      def log_count(query_options, table_name, ms)
        if logger && logger.debug?
          table_name ||= 'Content::Item'
          table_name = query_options[:conditions][:content_type] if query_options.has_key? :conditions and query_options[:conditions].has_key? :content_type
          table_name = table_name.to_s.gsub('::','').tableize
          sql = "SELECT COUNT(*) FROM #{table_name}"
          conds = map_conditions(query_options[:conditions]) if query_options.has_key? :conditions
          sql = sql + " WHERE #{conds}" unless conds.blank?
          sql = sql + " ORDER BY #{query_options[:order].inspect}" if query_options.has_key? :order
          sql = sql + " LIMIT #{query_options[:limit]}" if query_options.has_key? :limit
          name = '%s (%.1fms)' % [table_name.classify, ms]
          logger.debug(format_log_entry(name, sql.squeeze(' ')))
        end
      end

      def log_select(query_options, table_name, columns, ms)
        if logger && logger.debug?
          table_name ||= 'Content::Item'
          table_name = query_options[:conditions][:content_type] if query_options.has_key? :conditions and query_options[:conditions].has_key? :content_type
          table_name = table_name.to_s.gsub('::','').tableize
          sql = "SELECT #{columns} FROM #{table_name}"
          conds = map_conditions(query_options[:conditions]) if query_options.has_key? :conditions
          sql = sql + " WHERE #{conds}" unless conds.blank?
          sql = sql + " ORDER BY #{query_options[:order].inspect}" if query_options.has_key? :order
          sql = sql + " LIMIT #{query_options[:limit]}" if query_options.has_key? :limit
          name = '%s (%.1fms)' % [table_name.classify, ms]
          logger.debug(format_log_entry(name, sql.squeeze(' ')))
        end
      end

      def log_update(id, attributes, table_name, ms)
        if logger && logger.debug?
          table_name ||= 'Content::Item'
          table_name = table_name.to_s.gsub('::','').tableize
          sql = "UPDATE #{table_name} SET "
          sql = sql + attributes.reject {|k,v| k.to_s == "__id"}.collect {|k,v| "#{k} = #{v.inspect}" }.join(", ")
          sql = sql + " WHERE id = #{id}"
          name = '%s (%.1fms)' % [table_name.classify, ms]
          logger.debug(format_log_entry(name, sql.squeeze(' ')))
        end
      end

      def log_delete(id, table_name, ms)
        if logger && logger.debug?
          table_name ||= 'Content::Item'
          table_name = table_name.to_s.gsub('::','').tableize
          sql = "DELETE #{table_name} WHERE id = #{id}"
          name = '%s (%.1fms)' % [table_name.classify, ms]
          logger.debug(format_log_entry(name, sql.squeeze(' ')))
        end
      end

      def map_operator(op)
        {
          :streq => "=",
          :strinc => "includes",
          :strbw => "begins with",
          :strew => "ends with",
          :strand => "includes all",
          :stror => "includes any",
          :stroreq => "includes one",
          :strrx => "matches",
          :numeq => "=",
          :numgt => ">",
          :numge => ">=",
          :numlt => "<",
          :numle => "<=",
          :numbt => "between",
          :numoreq => "any",
          :ftsph => "contains phrase",
          :ftsand => "contains all",
          :ftsor => "contains any",
          :ftsex => "contains"
        }[op]
      end
      
      def map_conditions(conditions)
        conditions.reject {|k,v|
          k == :content_type
        }.collect {|k,v| 
          if v.is_a?(Hash)
            "#{k.to_s.gsub('__', '')} #{map_operator(v.keys.first)} #{v.values.first.inspect}"
          else
            "#{k.to_s.gsub('__', '')} = #{v.inspect}"
          end
        }.join(" AND ")
      end
      
      def format_log_entry(message, dump = nil)
        if ActiveRecord::Base.colorize_logging
          if @@row_even
            @@row_even = false
            message_color, dump_color = "4;36;1", "0;1"
          else
            @@row_even = true
            message_color, dump_color = "4;35;1", "0"
          end

          log_entry = "  \e[#{message_color}m#{message}\e[0m   "
          log_entry << "\e[#{dump_color}m%#{String === dump ? 's' : 'p'}\e[0m" % dump if dump
          log_entry
        else
          "%s  %s" % [message, dump]
        end
      end
    end
  end
end

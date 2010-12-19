module AppTable
  module Config
    #
    # == AppTable Columns
    #
    class Columns < Collection
      
      def initialize(config, active_record_class)
        super(config)
        @active_record_class = active_record_class
        configure_default
      end

      def add(*args, &block)
        block ||= proc { |column_name| Column.new(column_name.to_sym, @active_record_class) }
        super(*args, &block)
      end

      def find_by_name(name)
        find { |c| c.identical?(name)}
      end
      alias_method :[], :find_by_name

      def configure_default
        attribute_names = @active_record_class.columns.collect{ |c| c.name =~ /(^|_)id$/ ? nil : c.name }
        attribute_names.compact!
        add(*attribute_names)
      end

      #
      # Adjust column width for 0%
      # If you have set, then them will be reserved
      #
      def adjust_column_width
        grouped_columns = group_by{|column| column.width == "0%" ? "without" : "with"};
        with = grouped_columns["with"] || []
        without = grouped_columns["without"] || []
        # origin 5% keeped for selection column width
        used = with.inject(5){|total, column| column.width =~ /(\d+)%$/ ? total + $1.to_i : total}
        begin
          avg_width = (100 - used) / without.size
          left_width = (100 - used) % without.size
          without.each{|col| col.width = "#{avg_width}%"}
          without.last.width = "#{avg_width + left_width}%"
        end if not without.empty?
      end
    end
  end
end

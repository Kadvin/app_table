module AppTable
  module Extension
    module ViewHelper
      def app_table_config
        controller.__send__(:app_table_config)
      end

      # =提供通过Helper定制化方式定制某个列显示值
      def app_table_column_value (record, column)
        value = if app_table_column_override?(column)
          send(app_table_column_override(column), record, column)
        else
#          if( column.column and column.column.enum? )
#            column.column.enum_text(record.send(column.name))
#          else
            name = column.name.to_s
            name = /_id$/ =~ name ? name[0..-4] : name
            record.send(name) rescue "未知属性:#{column.name}"
#          end
        end
        if String === value and column.max_words
          value.truncate(column.max_words)
        else
          value
        end
      end

      # 判断该列有没有定义定制化的显示方法
      def app_table_column_override?(column)
        respond_to?(app_table_column_override(column))
      end
      #
      # 对于名称为name的字段，在Helper方法里面定义了方法
      # app_table_name_column(record, column)
      #
      def app_table_column_override(column)
        "app_table_#{column.name.to_s.gsub('?', '')}_column" # parse out any question marks (see issue 227)
      end

      #
      # ==如何获取一个记录的Selection Value
      # 默认取对象id，如果你在Helper里面定义一个
      #   def app_table_selection_value(record)
      #     # your code
      #   end
      # 就会按照你定义的逻辑获取
      def app_table_selection_of(record)
        if respond_to?(:app_table_selection_value)
          send(:app_table_selection_value, record)
        else
          record.id
        end
      end

    end
  end
end

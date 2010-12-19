module AppTable
  module Config
    class Core
      attr_accessor :page_size, :prefix, :sort_by, :selection_mode,
        :query_options, :html_options, :action, :paginate, :skin, :skin_module
      attr_reader :model, :model_id, :columns, :buttons

      cattr_reader :default_page_size
      @@default_page_size = 20
      
      def initialize(model_id, options = {})
        @skin  = options.delete(:skin) || :endless
        @skin_module = self.class.modulize_skin!(@skin)
        # Options will be stripped as query conditions
        options.symbolize_keys!
        @model_id = model_id.to_s.singularize
        @model = @model_id.camelize.constantize
        # action is the controller's action name
        @action = options.delete(:action) || :index
        # paginate was used to specify the pagination method
        @paginate = options.delete(:paginate) || :paginate
        # TODO thinkof Rails 3 query interface
        @query_options = options.slice(:include, :select, :joins, :from, :conditions)

        @prefix = options.delete(:prefix)

        @selection_mode = :multiple
        @page_size ||= @@default_page_size
        @columns = Columns.new(self, self.model)
        @buttons = Buttons.new(self)
      end

      def columns=(columns)
        @columns.clear
        columns.collect! {|c| c.to_sym}
        @columns.add(*columns)
      end

      def buttons=(buttons)
        @buttons.clear
        buttons.collect!{|c| c.to_sym}
        @buttons.add(*buttons)
      end

      def adjust_after_configure
        @columns.adjust_column_width if @columns.any?{ |col| col.width == "0%"}
      end

      #
      # ==Translate the selection mode to html-control type
      # 
      def selection_type
        case selection_mode.to_s
        when /single/i then "radio"
        when /multiple/i then "checkbox"
        else "hidden"
        end
      end

      def selection_visibility
        case selection_mode.to_s
        when /single/i then "table-cell"
        when /multiple/i then "table-cell"
        else "none"
        end
      end

      def name; model_id.to_s end
      
      def identify; name + "_page" end

      def self.modulize_skin!(skin)
        klass = "#{skin}_table_skin".classify
        klass.constantize
      rescue
        raise format("Can't find skin module with name = %s", klass)
      end
    end
  end
end

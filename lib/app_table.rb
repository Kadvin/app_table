#
# =AppTable
#
# Browse the active-records paginatively
# 
# ==Features:
#
# === Model Aspects
# * Model oriented query
# * Cross-Model Query
# * Order
# * Grouping, support customized group policy
#
# === View Aspects
# * Toolbar
# * Header
# * Selection
# * Statusbar
# * Even/odd coloring
#
module AppTable
  def self.included(base)
    base.extend(ClassMethods)
    base.class_inheritable_hash :app_table_configs
    base.app_table_configs = {}
  end

  #
  # == Module extends by the ActionController::Base
  #
  module ClassMethods
    def browse_as_table(model_id = nil, options = {})
      # Admin::TopicsController -> Admin::Topics -> admin/topics
      options[:prefix] ||= "/" + self.to_s.sub(/Controller$/, '').underscore
      # Admin::TopicsController -> TopicsController -> Topics -> Topic -> topic
      guess_model_id = self.to_s.demodulize.sub(/Controller$/, '').singularize.underscore
      if model_id # developer has specify a explity model_id, such as: topic, topics
        model_id = model_id.to_s        # developer maybe specify it as a symbol
        model_id = model_id.singularize # developer maybe declair it in plural-form
      else        # use the gussed model_id
        model_id = guess_model_id
      end
      # TopicsController: browse_as_table :topic -> action = :index,  means GET /topics/index
      # OtherController : browse_as_table :topic -> action = :topics, means GET /other/topics
      options[:action] = (guess_model_id == model_id) ? :index : model_id.pluralize

      config = AppTable::Config::Core.new(model_id, options)
      self.app_table_configs[config.action.to_sym] = config
      yield config if block_given?
      config.adjust_after_configure

      # self is the source controller class
      self.send(:include, InstanceMethods) unless self.included_modules.include?(InstanceMethods)

      # Alias the default frame and page actions as controller actions to be visited by user
      # table_frame -> index
      self.send(:alias_method, config.action, :table_frame)
      # table_page  -> table_index_page
      self.send(:alias_method, "table_#{config.action}_page", :table_page)
    end

    #
    # == Get the app_table_config for the controller class
    #
    def app_table_config(action = :index)
      self.app_table_configs[action.to_sym]
    end
  end

  # == Module included by the ActionController::Base
  module InstanceMethods
    def self.included(base)
      # those two action should be exposed
      base.hide_action(:table_frame, :table_page)
    end
    #
    # == handle: GET /topics/index
    #
    def table_frame
      sortby = params[:sortby] || app_table_config.sort_by
      skin = app_table_config.skin
      render(:template => "/#{skin}_app_table/table_frame", :locals=>{:sortby=>parse_sortby(sortby)})
    end

    #
    # == handle: GET /topics/index_page?page=X&sortby=YY [ASC|DESC]&current_group=ZZ
    #
    def table_page
      page, sortby ,current_group = params[:page] || "1",
        params[:sortby] || app_table_config.sort_by,
        params[:current_group]
      records = retrieve(page, sortby)
      skin = app_table_config.skin
      host, view = if ActiveSupport::OrderedHash === records
        [records.origin_records, "/#{skin}_app_table/grouped_view"]
      else
        [records, "/#{skin}_app_table/list_view"]
      end
      headers['per_page'] = host.per_page.to_s
      headers['total_entries'] = host.total_entries.to_s
      headers['current_page'] = host.current_page.to_s
      headers['total_pages'] = host.total_pages.to_s
      render(:partial=>view, :locals=>{:records=>records, :current_group=>current_group, :sortby=> parse_sortby(sortby)})
    end

    protected
      # Retrieve a page data order by sortby
      def retrieve(page, sortby)
        column = nil
        if sortby
          column = parse_sortby(sortby).first
          sortby = app_table_config.columns[column].translate_sortby(sortby)
        end
        conditions = app_table_config.query_options[:conditions]
        # 支持动态条件，动态条件为一个symbol，代表内部函数名称
        conditions = send(conditions) if conditions.is_a?(Symbol)
        options = app_table_config.query_options.merge(
          :page       => page,
          :per_page   => app_table_config.page_size,
          :order      => sortby,
          :conditions => conditions
        )
        results = send(app_table_config.paginate, options)
        if( column && app_table_config.columns[column].groupby )
          ordered_hash = results.group_by( &app_table_config.columns[column].groupby )
          ordered_hash.instance_eval do
            @results = results
            def origin_records; @results end
            def key_by_hash(hash)
              keys.find{|key|key.hash == hash.to_i}
            end
          end
          ordered_hash
        else
          results
        end
      end

      def parse_sortby (sortby)
        sortby =~ /^([\w\.]+)\s*(asc|desc)?/i
        [$1, $2]
      end

      # Find the app_table_config according to the action name
      def app_table_config
        action = if action_name.to_s =~ /table_([\w]+)_page/
          $1
        else
          action_name
        end
        # Old version compatitable
        action = :table_index_page if action == :table_page
        self.class.app_table_config(action)
      end

      def paginate(options)
        app_table_config.model.paginate(options)
      end

  end
end
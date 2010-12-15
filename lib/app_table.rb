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
  end

  #
  # == Module extends by the ActionController::Base
  #
  module ClassMethods
    def browse_as_table(model_id, options = {})
      
    end
  end

  # == Module included by the ActionController::Base
  module InstanceMethods
    def table_frame

    end

    def table_page

    end
  end
end
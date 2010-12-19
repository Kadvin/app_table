# Include hook code here
require 'app_table'
begin
  ActionController::Base.send(:include, AppTable)
  ActionView::Base.send(:include, AppTable::Extension::ViewHelper)
  #ActionController::Routing::RouteSet::Mapper.send(:include, AppTable::Extension::RouteMapper)
rescue
  raise $! unless Rails.env.production?
end

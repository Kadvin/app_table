module AppTable
  module Config
    #
    # = Buttons of AppTable
    #
    class Buttons < Collection

      def initialize(config)
        super(config)
        configure_default
      end
      
      def find_by_name(name)
        find { |c| c.identical?(name) }
      end
      alias_method :[], :find_by_name
      
      def add(*args, &block)
        block ||= proc do |i|
          button = Button.new(i.to_sym)
          button.prefix = config.prefix
          button
        end
        super(*args, &block)
      end

      def configure_default
        config.skin_module.default_actions.each do |action, options|
          action = action.to_s
          button = Button.new(action)
          button.prefix = config.prefix
          options.each do | k, v|
            button.send(k.to_s+"=", v)
          end
          @set << button
        end
      end
    end
  end
end

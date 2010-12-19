require 'ostruct'

module AppTable
  module Config
    #
    # ==Single Element of the AppTable
    #
    class Element < OpenStruct
      
      def initialize(name)
        super()
        self.name = name
      end

      def identical?(other)
        if other.is_a?(Element)
          self == other
        else
          self.name.to_sym == other.to_sym
        end
      end

      delegate :merge, :to => :table
    end
  end
end

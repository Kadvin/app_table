module AppTable
  module Config
    #
    # = The Button of the table
    # The button can be placed in two mode:
    #  1. shared mode: header/footer
    #  2. none-share mode: display inline in the record row
    # And it's enable/disable status depends on the selected records
    #  How to control it status when selection changed for shared button?
    #
    class Button < Element
      attr_accessor :label, :image, :prefix
      attr_reader :sub_buttons

      def initialize(name, label = nil)
        super(name)
        @sub_buttons = []
        @label = label
        @label ||= name
        @image = "/images/#{name}.png"
        self[:onclick] = "AppTable.Button.activate(this)"
      end

      def add(*sub_btns)
        @sub_buttons.concat sub_btns
      end
      alias_method :<<, :add

      def url=(value)
        table[:url] =  value % (prefix || "" )
      end
    end
  end
end

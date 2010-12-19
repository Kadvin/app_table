module AppTable
  module Config
    #
    # == Element Collection of AppTable
    #
    class Collection
      include Enumerable
      attr_reader :config
      delegate :each, :size, :clear, :to => :@set

      def initialize(config)
        @set = []
        @config = config
      end

      def exclude(*args)
        args.flatten! # allow [] as a param
        args = args.collect{ |a| a.to_sym }
        args.each do |a|
          if block_given?
            v = yield a
            @set.delete(v) if v
          else
            @set.delete_if{|item| item.identical?(a)}
          end
        end
      end

      #
      # add(:a, :b, :c)
      # add(:a, :b, :before=>:c)
      #
      def add(*args, &block)
        options = args.extract_options!
        args.flatten! # allow [] as a param
        args.collect!{ |arg| arg.to_sym }
        items = args.map(&block)
        items.compact! #删除空对象
        if before = options[:before]
          position = 0
          @set.each do |item|
            break if item.name.to_sym == before.to_sym
            position += 1
          end
          @set.insert(position, *items)
        else
          @set.concat(items)
        end
      end
      alias_method :<<, :add
    end
  end
end

module AppTable
  module Config
    #
    # ==AppTable Column
    # 
    class Column < Element

      include ActionView::Helpers::DateHelper
      
      NESTED_PATTERN = /([^.]*)\.(.*)$/

      def initialize(name, active_record_class, width = "0%")
        super(name)
        self.plural_name = $1.pluralize if name.to_s =~ NESTED_PATTERN
        self.column = dig_column(active_record_class, name)# Maybe nil
        self.width = width
        self.max_words = nil
        # Dig the column label from resources
        column_name = name.to_s.gsub(/\./, "_") # Nested Attr: schedule_job.type -> schedule_job_type
        column_name = (/_id$/ =~ column_name) ? column_name[0..-4] : column_name # FK: schedulable_id -> schedulable
        key = "#{active_record_class.name.underscore}.attributes.#{column_name.downcase}".to_sym
        # Resource First
        self.label = I18n.t(key, :raise=>true) rescue nil
        if( self.column.nil? )
          self.label = column_name.titleize unless self.label
          self.sortable = false
        else
          self.label = self.column.human_name unless self.label
          self.sortable = self.column.type != :text
          self.groupby = default_column_group_by(self.column, self.name)
        end
      end

      #
      # == Dig the column
      #  Given:
      #    Post belongs_to Topic named as topic
      #    Topic has_one Attachment named as attachment
      #    Attachment has attribute named as file
      #  Then: dig_column(Post, :'topic.attachement.file')
      #     -> dig_column(Topic, :'attachment.file')
      #     -> dig_column(Attachment, :'file')
      def dig_column(klass, name_or_segments)
        segments = name_or_segments.is_a?(Array) ? name_or_segments : name_or_segments.to_s.split(".")
        column_name = segments.shift
        if( segments.empty? )
          return klass.columns_hash[column_name]
        else
          reflection = klass.reflect_on_association(column_name.to_sym)
          raise "Can't find reflection for: #{klass}.#{column_name}" unless reflection
          raise "Can't fetch column from has_many association: #{klass}.#{column_name}" if reflection.macro == :has_many
          return dig_column(reflection.klass, segments)
        end
      end

      #
      # == Create Default Grouping for AppTable Column
      # Default Grouping support：
      # * Group by enum
      # * Group by time interval
      #
      # Parameters:
      # * column: the column
      # * name: the attribute name of the column in the host object
      #   such as: author_id for Post, means the Post#author_id
      #          : topic.author_id for Post, means the Post#topic#author_id
      def default_column_group_by(column, name)
        if( column.respond_to?(:groupby) )
          column.groupby
        elsif([:date, :time, :datetime, :timestamp].include?(column.type))
          proc do |record|
            value = record.send(name)
            value && distance_of_time_in_words(value, Time.now)
          end
        end
      end

      #
      # ==Translate sortby of this column
      # There are two sortby case：
      # * Common Column： sortby = name [ASC|DESC]
      # * Nested Column： sortby = another.name [ASC|DESC]
      # The Second case should convert the host name into plural format(or other)
      # * sortby = anothers.name
      def translate_sortby(sortby)
        return sortby if not self.name.to_s =~ NESTED_PATTERN
        sortby.gsub($1, self.plural_name)
      end

      #
      # = Judge this column is nested type or not
      #
      def nested_column?
        self.name.to_s =~ NESTED_PATTERN
      end
    end
  end
end

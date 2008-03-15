module ActiveRecord
  # By Ryan Heneise
  # Extends ActiveRecord to automatically create a permalink field 
  # when a record is created, if the permalink field is available. 
  # use_permalink must be specified in the model for this to work. 
  # 
  # Does not allow the value of the permalink to be specified. 
  # If the value is specified, it will be overwritten by the
  # generated permalink. 
  # 
  # ==Usage
  # use_permalink :name_of_field_from_which_to_extract_permalink
  module Permalink
    
    def self.append_features(base)
      super
      base.extend(ClassMethods)  
    end
    
    def self.included(base)
      base.class_eval do
        alias_method :create_without_permalink, :create
        alias_method :create, :create_with_permalink
        
        alias_method :update_without_permalink, :update
        alias_method :update, :update_with_permalink
      end
    end
    
    def create_with_permalink
      self[:permalink] = generate_permalink if respond_to?(:permalink)# && self.permalink.nil?
      create_without_permalink
    end
    
    def update_with_permalink
      self[:permalink] = generate_permalink if respond_to?(:permalink)# && self.permalink.nil?
      update_without_permalink
    end
    
    def generate_permalink
      scope = "AND t.homebase_id = #{Homebase.current_homebase.id}" unless Homebase.current_homebase.nil?
      count = self.class.find_by_sql(["SELECT * FROM #{self.class.table_name} t WHERE t.#{permalink_field} = ? #{scope} ORDER BY t.id", self["#{permalink_field}"] ])
      
      # If no other records will match, just give it a simple permalink based on the permalink_field
      # Otherwise, append a number on to the end of the permalink to distinguish it from the others. 
      # If it's a new record, just add one to the sum of the other records. 
      # If it's not a new record, then index the records and attach that row's index as an identifier. 
      if count.length > 0
        if self.new_record? 
          link = self["#{permalink_field}"] + "-" + (count.length + 1).to_s
        else
          i = (count.index(self.class.find(self.id))).to_i + 1
          link = self.new_record? ? link = self["#{permalink_field}"] + "-" + (count.length + 1).to_s : self["#{permalink_field}"] + (i == 1 ? "" : "-" + i.to_s)
        end
      else
        link = self["#{permalink_field}"]
      end
      
      return link.to_url
    end
    
    module ClassMethods
      def use_permalink(options)
        permalink_field = options.to_s
        write_inheritable_attribute(:permalink_field, permalink_field)
        class_inheritable_reader :permalink_field
      end
    end
    
  end  
end




class String
  # From Typo:
  # Converts a post title to its-title-using-dashes
  # All special chars are stripped in the process  
  def to_url
    result = self.downcase

    # replace quotes by nothing
    result.gsub!(/['"]/, '')

    # strip all non word chars
    result.gsub!(/\W/, ' ')

    # replace all white space sections with a dash
    result.gsub!(/\ +/, '-')

    # trim dashes
    result.gsub!(/(-)$/, '')
    result.gsub!(/^(-)/, '')

    result
  end
end
module ActiveRecord

  module UserMonitor

    def self.included(base)

      base.class_eval do
        alias_method :create_without_user, :create
        alias_method :create, :create_with_user
        
        alias_method :create_without_homebase, :create
        alias_method :create, :create_with_homebase

        alias_method :update_without_user, :update
        alias_method :update, :update_with_user
      end
    end

    def create_with_user
      if !User.current_user.nil?
        user = User.current_user.id
        self[:created_by] = user if self.respond_to?(:created_by) && self.created_by.nil?
        self[:updated_by] = user if self.respond_to?(:updated_by)
      end
      create_without_user
    end
    
    def create_with_homebase
      if !Homebase.current_homebase.nil?
        homebase = Homebase.current_homebase.id
        self[:homebase_id] = homebase if self.respond_to?(:homebase_id) && self.homebase_id.nil?        
      end
      create_without_homebase
    end

    def update_with_user
      if !User.current_user.nil?
        user = User.current_user.id
        self[:updated_by] = user if self.respond_to?(:updated_by)
      end
      update_without_user
    end

    def created_by
      begin
        User.find(self[:created_by])
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end

    #def created_by=(user)
    #  self[:created_by] = user.id
    #end

    def updated_by
      begin
        User.find(self[:updated_by])
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end

    def updated_by=(user)
      self[:updated_by] = user.id
    end

  end

  class Base

    @@default_user_model = :users
    cattr_accessor :user_model_name

    def self.user_model_name
      if @@user_model.nil?
        @@default_user_model
      else
        @@user_model
      end
    end

    def self.relates_to_user_in(model)
      self.user_model_name = model
    end

    def user_model
      Object.const_get(self.user_model_name.to_s.singularize.humanize)
    end
  end
end
module UserAuditor
  def self.append_features(base)
    base.before_create do |model|
      model.created_by ||= User.current_user.id if model.respond_to?(:created_by) && !User.current_user.nil?
    end
    base.before_create do |model|
      model.updated_by ||= User.current_user.id if model.respond_to?(:updated_by) && !User.current_user.nil?
    end
  end
end
class ExtendEmailFields < ActiveRecord::Migration
  def self.up
    change_column :emails, :subject, :text
    change_column :emails, :body, :text
    change_column :emails, :raw, :text
  end

  def self.down
    # no need to migrate down from this
  end
end

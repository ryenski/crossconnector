class AddExtendedProjectDescription < ActiveRecord::Migration
  def self.up
    add_column "projects", "excerpt", :text
    add_column "projects", "excerpt_html", :text
  end

  def self.down
    remove_column "projects", "excerpt"
    remove_column "projects", "excerpt_html"
  end
end

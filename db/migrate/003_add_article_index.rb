class AddArticleIndex < ActiveRecord::Migration
  def self.up
    add_index :articles, :title
    add_index :articles, :uri
  end

  def self.down
    remove_index :articles, :title
    remove_index :articles, :uri
  end
end

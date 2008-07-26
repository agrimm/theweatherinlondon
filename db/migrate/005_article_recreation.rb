#Fix timestamps, add field local_id for the local identifier the repository gave to an article
class ArticleRecreation < ActiveRecord::Migration
  def self.up
    Article.delete_all
    add_column :articles, :local_id, :integer, :null =>true
    add_column :articles, :created_at, :datetime
    add_column :articles, :updated_at, :datetime
  end

  def self.down
    remove_column :articles, :updated_at
    remove_column :articles, :created_at
    remove_column :articles, :local_id
  end
end

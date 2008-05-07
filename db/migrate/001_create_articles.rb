class CreateArticles < ActiveRecord::Migration
  def self.up
    create_table :articles do |t|
      t.column :uri,  :string
      t.column :title, :string
    end
  end

  def self.down
    drop_table :articles
  end
end

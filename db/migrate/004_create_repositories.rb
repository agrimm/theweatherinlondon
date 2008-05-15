class CreateRepositories < ActiveRecord::Migration
  def self.up
    create_table :repositories do |t|
      t.column :abbreviation, :string
      t.column :short_description, :string

      t.timestamps
    end

    add_column :articles, :repository_id, :integer, :null => false
  end

  def self.down
    remove_column :articles, :repository_id

    drop_table :repositories
  end
end

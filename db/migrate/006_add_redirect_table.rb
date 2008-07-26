class AddRedirectTable < ActiveRecord::Migration
  def self.up
    create_table :redirects, :id => false do |t|
      t.integer "redirect_source_repository_id"
      t.integer "redirect_source_local_id"
      #There does not seem to be a need yet for redirects occur between repositories, so redirect_target_repository_id would be redundant
      t.string "redirect_target_title"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index :redirects, [:redirect_source_repository_id, :redirect_source_local_id], :name=>'index_redirects_on_source'
    add_index :redirects, [:redirect_source_repository_id, :redirect_target_title], :name=>'index_redirects_on_target'
  end

  def self.down
    drop_table "redirects"
  end
end

# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 4) do

  create_table "articles", :force => true do |t|
    t.string  "uri"
    t.string  "title"
    t.integer "repository_id", :null => false
  end

  add_index "articles", ["title"], :name => "index_articles_on_title"
  add_index "articles", ["uri"], :name => "index_articles_on_uri"

  create_table "repositories", :force => true do |t|
    t.string   "abbreviation"
    t.string   "short_description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end

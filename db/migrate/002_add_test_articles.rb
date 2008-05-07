class AddTestArticles < ActiveRecord::Migration
  def self.up
    self.down
    #Article.create!(:uri => "http://en.wikipedia.org/wiki/Hello_world_program", :title => "Hello world program")
    #Article.create!(:uri => "http://en.wikipedia.org/wiki/Wolbachia", :title => "Wolbachia")
  end

  def self.down
    Article.delete_all
  end
end

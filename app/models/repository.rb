class Repository < ActiveRecord::Base
  has_many :articles

  def generate_uri(article_title)
    require 'uri'
    underscored_title = article_title.gsub(" ", "_")
    if (abbreviation =~ /(.*)wiki/)
      return URI.escape("http://"+$1+".wikipedia.org/wiki/" + underscored_title)
    else
      raise "Unknown repository!"
    end
  end

end

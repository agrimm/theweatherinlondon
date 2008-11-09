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

  #Return all articles that match the requested phrase
  #Probably should only return one article, but return an array just in case
  def find_matching_articles(phrase)
    return [] if phrase_is_boring?(phrase)
    matching_articles = articles.find(:all, :conditions => ["title = ?", phrase.to_s], :limit => 1)
    matching_articles
  end

  #Determine if a phrase is boring
  #Currently, it deems as boring any phrases with no or one boring words
  def phrase_is_boring?(phrase)
    words = phrase.words
    boring_words = %w{a and also are be been for get has in is just me of on only see than this the there was january february march april may june july august september october november december}
    number_non_boring_words = 0
    words.each do |word|
      number_non_boring_words += 1 unless boring_words.include?(word.downcase) #Not unicode safe?
      #number_non_boring_words += 1 unless boring_words.include?(word.chars.downcase) #Unicode safe
    end
    return true unless number_non_boring_words > 1
  end

  def try_this_phrase_or_longer?(phrase)
    if phrase_is_boring?(phrase)
      return true #Otherwise it chews up too much server time
    end
    potentially_matching_article = articles.find(:first, :conditions => ["title like ?", phrase.to_s + "%"])
    return ! potentially_matching_article.nil?
  end

  #Return the maximum length a document should be, to avoid server resource issues
  def self.maximum_allowed_document_size
    15000
  end

end

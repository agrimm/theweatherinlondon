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
  def find_matching_articles(phrase, existing_article_titles)
    return [] if phrase_is_boring?(phrase, existing_article_titles)
    matching_articles = articles.find(:all, :conditions => ["title = ?", phrase], :limit => 1)
    matching_articles
  end

  #Determine if a phrase is boring
  #Currently, it is expected by contract to deem as boring any phrases with no or one boring words
  #As a convenience to the calling method, it may deem as boring any phrases that have already been found, but it is not part of the contract, and it won't take into account redirects
  def phrase_is_boring?(phrase, existing_article_titles)
    #if existing_article_titles.any?{|existing_article_title| existing_article_title.chars.downcase.to_s.include?(phrase.chars.downcase)} #Unicode safe, too slow? :(
    if existing_article_titles.any?{|existing_article_title| existing_article_title.downcase.include?(phrase.downcase)} #Not unicode safe?
      return true
    end
    words = break_up_phrase(phrase)
    #count how many words are non-boring
    boring_words = %w{a and also are be been for get has in is just me of on only see than this the there was january february march april may june july august september october november december}
    number_non_boring_words = 0
    words.each do |word|
      number_non_boring_words += 1 unless boring_words.include?(word.downcase) #Not unicode safe?
      #number_non_boring_words += 1 unless boring_words.include?(word.chars.downcase) #Unicode safe
    end
    return true unless number_non_boring_words > 1
  end

  #Informs the caller if they should try a longer phrase than the current one in order to get a match
  def try_longer_phrase?(phrase, existing_article_titles)
    if phrase_is_boring?(phrase, existing_article_titles)
      return true #Otherwise it chews up too much server time
    end
    potentially_matching_articles = articles.find(:all, :conditions => ["title like ?", phrase + "%"], :limit=>1)
    return ! potentially_matching_articles.empty?
  end

  #Todo: this method is also in article.rb, indicating a DRY violation
  def break_up_phrase(phrase)
    words = phrase.split(/[[:space:],.""'']+/)
    words
  end

  #Return the maximum length a document should be, to avoid server resource issues
  def self.maximum_allowed_document_size
    15000
  end

end

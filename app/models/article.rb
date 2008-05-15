class Article < ActiveRecord::Base
  validates_presence_of :title
  belongs_to :repository

  #Return the maximum length a document should be, to avoid server resource issues
  def self.maximum_allowed_document_size
    15000
  end

  #If a URI exists, return it, else dynamically generate it from the article title
  def get_uri
    unless self.uri == nil
      return self.uri
    else 
      return repository.generate_uri(title)
    end
  end

  def self.break_up_phrase(phrase)
    words = phrase.split(/[[:space:],.""'']+/)
    words
  end

  #Determine if a phrase is boring
  #That is, it has one or zero non-boring words
  def self.phrase_is_boring?(phrase)
    words = break_up_phrase(phrase)
    #count how many words are non-boring
    boring_words = %w{a and also are be been for get has in is just me of on only see than this the there was january february march april may june july august september october november december}
    number_non_boring_words = 0
    words.each do |word|
      number_non_boring_words += 1 unless boring_words.include?(word.chars.downcase)
    end
    return true unless number_non_boring_words > 1
  end

  #Return all articles that match the requested phrase
  #Probably should only return one article, but return an array just in case
  def self.find_matching_articles(phrase, repository)
    return [] if phrase_is_boring?(phrase)
    articles = find(:all, :conditions => ["title = ? and repository_id = ?", phrase, repository], :limit => 1)
    articles
  end

  #Informs the caller if they should try a longer phrase than the current one in order to get a match
  def self.try_longer_phrase?(phrase, repository)
    if phrase_is_boring?(phrase)
      return true #Otherwise it chews up too much server time
    end
    potentially_matching_articles = find(:all, :conditions => ["title like ? and repository_id = ?", phrase + "%", repository], :limit=>1)
    return !potentially_matching_articles.empty?
  end

  #Read in a document, and return an array of phrases and their matching articles
  #Strategy: split into words, then iterate through the words
  def self.parse_text_document(document_text, repository)
    parse_results = []
    words = break_up_phrase(document_text)
    raise(ArgumentError, "Document has too many words") if words.size > maximum_allowed_document_size
    i = 0
    while(true)
      j = 0
      phrase = words[i + j]
      while(true)
        matching_articles = find_matching_articles(phrase, repository)
        matching_articles.each do |matching_article|
          parse_results << [phrase, matching_article]
        end
  
        break unless (try_longer_phrase?(phrase, repository) and i + j + 1 < words.size)
        j = j + 1
        phrase += " "
        phrase += words[i + j]
      end

      break unless (i + 1 < words.size)
      i = i + 1
    end

    cleaned_results = clean_results(parse_results)
    cleaned_results
  end

  #a method to get rid of the duplicate results
  def self.clean_results(parse_results)
    parse_results.delete_if {|x| !(x[0].include?(" ") )}
    #Get rid of results with a phrase shorter than another phrase in parse_results
    #Get rid of results with a phrase already included in cleaned_results
    cleaned_results = []
    0.upto(parse_results.size-1) do |i|
      is_non_duplicate_result = true
      current_result = parse_results[i]
      current_result_phrase = parse_results[i][0]
      0.upto(parse_results.size-1) do |j|
        next if i == j
        other_result_phrase = parse_results[j][0]
        if current_result_phrase == other_result_phrase and i > j #Identical phrases, current result not the first one
          is_non_duplicate_result = false
          break
        end
        if other_result_phrase.size > current_result_phrase.size and other_result_phrase.include?(current_result_phrase)
          is_non_duplicate_result = false
          break
        end
      end
      if is_non_duplicate_result
        cleaned_results << current_result
      end
    end 
    cleaned_results
  end

end

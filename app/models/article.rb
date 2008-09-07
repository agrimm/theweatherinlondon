class Article < ActiveRecord::Base
  validates_presence_of :title
  belongs_to :repository

  #If a URI exists, return it, else dynamically generate it from the article title
  def get_uri
    unless self.uri == nil
      return self.uri
    else 
      return repository.generate_uri(title)
    end
  end

  #If the article is a redirect, return the redirect target, else return nil
  def redirect_target
    if defined?(@redirect_target)
      @redirect_target
    else
      results = Article.find_by_sql(["select articles.* from articles, redirects where redirects.redirect_source_repository_id = ? and redirects.redirect_source_local_id = ? and BINARY redirects.redirect_target_title = articles.title and redirects.redirect_source_repository_id = articles.repository_id", repository_id, local_id])
      raise "Can't happen case #{repository_id.to_s + " " + local_id.to_s} #{results.inject(""){|str, result| str + result.title + " " + result.repository_id.to_s} }" if results.size > 1
      @redirect_target = results.first
    end
  end

  def redirect_sources
    if defined?(@redirect_sources)
      @redirect_sources
    else
      #Table articles currently isn't indexed by repository_id and local_id, nor is table redirects indexed by redirect_target_title, so this would currently be slow
      @redirect_sources = Article.find_by_sql(["select articles.* from articles, redirects where BINARY redirects.redirect_target_title = ? and redirects.redirect_source_repository_id = ? and redirects.redirect_source_repository_id = articles.repository_id and redirects.redirect_source_local_id = articles.local_id", title, repository_id])
    end
  end

  #To do: fix this kludge?
  def self.new_document(document_text, repository, markup)
    return Document.new(document_text, repository, markup)
  end

end

#A document submitted by the user
class Document

  def initialize(document_text, repository, markup)
    @repository = repository
    if (markup == "auto-detect") #Turn into symbol
      markup = markup_autodetect(document_text)
    end
    if (markup == "mediawiki")
      @parsed_document_text = parse_wiki_text(document_text.dup)
      @existing_article_titles = parse_existing_wiki_links(@parsed_document_text)
    else
      @parsed_document_text = document_text.dup
      @existing_article_titles = []
    end
    @words = break_up_phrase(@parsed_document_text)
    raise(ArgumentError, "Document has too many words") if @words.size > Repository.maximum_allowed_document_size
  end

  #Read in a document, and return an array of phrases and their matching articles
  #Strategy: split into words, then iterate through the words
  def parse
    parse_results = []
    0.upto(@words.size - 1) do |i|
      i.upto(@words.size - 1) do |j|
        phrase = @words[i..j].join(" ")
        matching_articles = @repository.find_matching_articles(phrase, @existing_article_titles)
        matching_articles.each do |matching_article|
          parse_results << [phrase, matching_article]
        end
        break unless @repository.try_longer_phrase?(phrase, @existing_article_titles)
      end
    end
    parse_results = clean_results(parse_results, @existing_article_titles)
  end

  #Determine if the text is in some sort of markup
  def markup_autodetect(document_text)
    markup = "plain"
    if document_text =~ %r{\[\[[^\[\]]+\]\]}im
      markup = "mediawiki"
    end
    markup
  end

  #Remove from MediaWiki text anything that is surrounded by <nowiki>
  def parse_nowiki(wiki_text)
    loop do
      #Delete anything paired by nowiki, non-greedily
      #Assumes that there aren't nested nowikis
      substitution_made = wiki_text.gsub!(%r{<nowiki>(.*?)</nowiki>}im,"")
      break unless substitution_made
    end
    wiki_text
  end

  #Remove from MediaWiki text anything within a template
  def parse_templates(wiki_text)
    loop do
      #Delete anything with paired {{ and }}, so long as no opening braces are inside
      #Should closing braces inside be forbidden as well?
      substitution_made = wiki_text.gsub!(%r{\{\{([^\{]*?)\}\}}im,"")
      break unless substitution_made
    end
    wiki_text
  end

  #Remove from MediaWiki text anything in an external link
  #This will remove the description of the link as well - for now
  def parse_external_links(wiki_text)
    #Delete everything starting with an opening square bracket, continuing with non-bracket characters until a colon, then any characters until it reaches a closing square bracket
    wiki_text.gsub!(%r{\[[^\[]+?:[^\[]*?\]}im, "")
    wiki_text
  end

  #Remove paired XHTML-style syntax 
  def parse_paired_tags(wiki_text)
    #Remove paired tags
    wiki_text.gsub!(%r{<([a-zA-Z]*)>(.*?)</\1>}im, '\2')
    wiki_text
  end

  #Remove non-paired XHTML-style syntax
  def parse_unpaired_tags(wiki_text)
    wiki_text.gsub!(%r{<[a-zA-Z]*/>}im, "")
    wiki_text
  end

  #Remove links to other namespaces (eg [[Wikipedia:Manual of Style]]) , to media (eg [[Image:Wiki.png]]) and to other wikis (eg [[es:Plancton]])
  def parse_non_direct_links(wiki_text)
    wiki_text.gsub!(%r{\[\[[^\[\]]*?:([^\[]|\[\[[^\[]*\]\])*?\]\]}im, "")
    wiki_text
  end

  #Remove from wiki_text anything that could confuse the program
  def parse_wiki_text(wiki_text)
    wiki_text = parse_nowiki(wiki_text)
    wiki_text = parse_templates(wiki_text)
    wiki_text = parse_paired_tags(wiki_text)
    wiki_text = parse_unpaired_tags(wiki_text)
    wiki_text = parse_non_direct_links(wiki_text)
    wiki_text = parse_external_links(wiki_text) #Has to come after parse_non_direct_links for now
    wiki_text
  end

  #Look for existing wikilinks in a piece of text
  def parse_existing_wiki_links(wiki_text)
    unparsed_match_arrays = wiki_text.scan(%r{\[\[([^\]\#\|]*)([^\]]*?)\]\]}im)
    parsed_wiki_article_titles = []
    unparsed_match_arrays.each do |unparsed_match_array|
      unparsed_title = unparsed_match_array.first
      parsed_title = unparsed_title.gsub(/_+/, " ") #This line is not heckle-proof
      parsed_wiki_article_titles << parsed_title
    end
    parsed_wiki_article_titles.uniq
  end

  def break_up_phrase(phrase)
    words = phrase.split(/[[:space:],.""'']+/)
    words
  end

  #a method to get rid of the duplicate results
  #to do: refactor this code
  def clean_results(parse_results, existing_article_titles)
    #parse_results.delete_if {|x| !(x[0].include?(" ") )} #This line may be redundant
    #Get rid of results with a phrase shorter than another phrase in parse_results
    #Get rid of results with a phrase already included in cleaned_results
    parse_results.uniq!
    cleaned_results = []
    0.upto(parse_results.size-1) do |i|
      is_non_duplicate_result = true
      current_result = parse_results[i]
      current_result_phrase = parse_results[i][0]
      0.upto(parse_results.size-1) do |j|
        next if i == j
        other_result_phrase = parse_results[j][0]
        #if current_result_phrase == other_result_phrase and i > j #Identical phrases, current result not the first one
        #  is_non_duplicate_result = false
        #  break
        #end
        if other_result_phrase.size > current_result_phrase.size and other_result_phrase.include?(current_result_phrase)
          is_non_duplicate_result = false
          break
        end
      end
      if is_non_duplicate_result
        cleaned_results << current_result
      end
    end 

    cleaned_results.delete_if do |phrase, matching_article|
      cleaned_results.any? do |other_phrase, other_article|
        matching_article.redirect_target == other_article
      end
    end
    cleaned_results.delete_if do |phrase, matching_article|
      existing_article_titles.any? do |article_title|
        (matching_article.redirect_target and matching_article.redirect_target.title.downcase == article_title.downcase) #Not unicode safe?
      end
    end
    cleaned_results
  end

end

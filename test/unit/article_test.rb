require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < Test::Unit::TestCase
  fixtures :articles
  fixtures :repositories
  fixtures :redirects

  def setup
    @empty_document = Document.new("", Repository.find(:first), "auto-detect")
    @af_uncyclopedia = Repository.find_by_abbreviation("af-uncyclopedia")
    @auto_detect = "auto-detect"
  end

  #The tests in this method may not make sense right now
  def dont_test_clean_results
    repository = Repository.find(:first)
    article1 = Article.create!(:title=> "a", :uri=>"http://www.example.com/1", :repository=>repository)
    article2 = Article.create!(:title=> "b", :uri=>"http://www.example.com/2", :repository=>repository)
    identical_results = [ ["Winter Olympic", article1] , ["Winter Olympic", article2] ]
    cleaned_results = Article.clean_results(identical_results)
    assert identical_results.size == 2, "Wrong number of original items"
    assert cleaned_results.size == 1, "Wrong number of final items"
    containing_results = [ ["Winter Olympic Games", article1] , ["Winter Olympic", article2] ]
    cleaned_results = Article.clean_results(containing_results)
    assert containing_results.size == 2, "Wrong number of original items"
    assert cleaned_results.size == 1, "Wrong number of final items"
  end

  def test_parse_nowiki
    generalized_syntax_parsing_testing(:parse_nowiki, "<nowiki>", "</nowiki>", true)
    generalized_syntax_parsing_testing(:parse_wiki_text, "<nowiki>", "</nowiki>", true)
  end

  def test_parse_templates
    generalized_syntax_parsing_testing(:parse_templates, "{{", "}}", true)
    generalized_syntax_parsing_testing(:parse_wiki_text, "{{", "}}", true)
  end

  def test_parse_external_links
    generalized_syntax_parsing_testing(:parse_external_links, "[http://www.example.com", "]", true)
    generalized_syntax_parsing_testing(:parse_wiki_text, "[http://www.example.com", "]", true)
  end

  def test_parse_paired_tags
    generalized_syntax_parsing_testing(:parse_paired_tags, "<ref>", "</ref>", false)
    generalized_syntax_parsing_testing(:parse_wiki_text, "<ref>", "</ref>", false)
  end

  def test_parse_unpaired_tags
    generalized_syntax_parsing_testing(:parse_unpaired_tags, "<references/>", nil, false)
    generalized_syntax_parsing_testing(:parse_wiki_text, "<references/>", nil, false)
  end

  def test_parse_non_direct_links
    generalized_syntax_parsing_testing(:parse_non_direct_links, "[[fr:", "]]", true)
    generalized_syntax_parsing_testing(:parse_wiki_text, "[[fr:", "]]", true)
  end

  #More generalized testing of syntax parsing
  #Assumptions: text is of a form 
  # pre_syntax_text SYNTAX_START inside_syntax_text SYNTAX_FINISH post_syntax_text
  #and if parsing_removes_inner_section is true, it'll end up as
  # pre_syntax_text post_syntax_text
  #else
  # pre_syntax_text inside_syntax_text post_syntax_text
  def generalized_syntax_parsing_testing(method_symbol, syntax_start, syntax_finish, parsing_removes_inner_section)
    pre_syntax_options = ["Internationalization\nLocalization\n", " Internationalization ", "Iñtërnâtiônàlizætiøn", " Iñtërnâtiônàlizætiøn ", " This is Iñtërnâtiônàlizætiøn (ie ǧø ĉȑȧẓẙ with the umlauts!?!). ","Hello: ", "[[Innocent bystander]]"]
    syntax_options = [ [syntax_start, syntax_finish], ["",""] ]
    inside_syntax_options = ["http://www.example.com", "Multi\nLine\nExample\n"]
    post_syntax_options = ["Iñtërnâtiônàlizætiøn", " Iñtërnâtiônàlizætiøn ", " This is Iñtërnâtiônàlizætiøn (ie ǧø ĉȑȧẓẙ with the umlauts!?!). ", "Hello: ", "[[Innocent bystander]]"]
    syntax_test_pairs = []
    pre_syntax_options.each do |pre_syntax_option|
      syntax_options.each do |syntax_option|
        inside_syntax_options.each do |inside_syntax_option|
          post_syntax_options.each do |post_syntax_option|
            if rand < 0.04
              syntax_start_option = syntax_option[0] || "" #May be syntax_start, or may be ""
              syntax_finish_option = syntax_option[1] || "" #May be syntax_finish, or may be ""
              unparsed_text = pre_syntax_option + syntax_start_option + inside_syntax_option + syntax_finish_option + post_syntax_option
              if (not (parsing_removes_inner_section) or (syntax_start_option.blank? and syntax_finish_option.blank?) )
                #Don't remove the inside text
                parsed_text = pre_syntax_option + inside_syntax_option + post_syntax_option
              else
                #Remove the inside text
                parsed_text = pre_syntax_option + post_syntax_option
              end
              syntax_test_pairs << [unparsed_text, parsed_text]
            end
          end
        end
      end
    end
    syntax_test_pairs_duplicate = syntax_test_pairs.dup
    syntax_test_pairs_duplicate.each do |first_pair|
      syntax_test_pairs_duplicate.each do |second_pair|
        syntax_test_pairs << [first_pair[0] + second_pair[0], first_pair[1] + second_pair[1] ]
      end
    end
    syntax_test_pairs.each do |syntax_test_pair|
      unparsed_text = syntax_test_pair[0]
      parsed_text = syntax_test_pair[1]
      assert_equal parsed_text, @empty_document.send(method_symbol, unparsed_text)
    end
  end

  def test_parse_existing_wiki_links
    wiki_text = "The rain in [[London]] is quite [[London#climate|wet]]"
    assert_equal ["London"], @empty_document.parse_existing_wiki_links(wiki_text)
  end

  def test_nested_templates
    wiki_text = "abc {{def {{ghi}} jkl}} mno"
    assert_equal "abc  mno", @empty_document.parse_templates(wiki_text)
  end

  def test_trickier_non_direct_links
    wiki_texts = ["start [[Image:wiki.png]]finish", "start[[Image:wiki.png|The logo of this [[wiki]]]] finish", "start[[:Image:wiki.png|The logo of this [[wiki]], which is the English Wikipedia]] finish"]
    wiki_texts.each do |wiki_text|
      assert_equal "start finish", @empty_document.parse_non_direct_links(wiki_text)
      assert_equal "start finish", @empty_document.parse_wiki_text(wiki_text)
    end
  end

  def test_no_side_effects_on_document_text
    document_text = "[[en:Wikipedia]]"
    original_document_text = document_text.dup
    repository = Repository.find_by_abbreviation("af-uncyclopedia")
    markup = "auto-detect"
    parse_text_document(document_text, repository, markup)
    assert_equal document_text, original_document_text
  end

  #Test that an article having the full title wikified deals with shortened versions of the title
  def test_handle_shorted_versions_of_wikified_titles
    repository = Repository.find_by_abbreviation("af-uncyclopedia")
    markup = "auto-detect"
    long_article = Article.find_by_title_and_repository_id("Maria Theresa of Austria", repository)
    short_article = Article.find_by_title_and_repository_id("Maria Theresa", repository)
    document_text_results_pairs = []
    document_text_results_pairs << ["#{long_article.title}", [ [long_article.title, long_article ] ] ]
    document_text_results_pairs << ["[[#{long_article.title}]]", [  ] ]
    document_text_results_pairs << ["#{long_article.title} : #{short_article.title} was born in", [ [long_article.title, long_article ] ] ]
    document_text_results_pairs << ["[[#{long_article.title}]] : #{short_article.title} was born in", [  ] ]
    document_text_results_pairs.each do |document_text_results_pair|
      document_text = document_text_results_pair[0]
      expected_results = document_text_results_pair[1]
      results = parse_text_document(document_text, repository, markup)
      assert_equal expected_results, results
    end
  end

  #Test whether the parser can handle non-ASCII text
  def test_non_ascii_text
    repository = Repository.find_by_abbreviation("af-uncyclopedia")
    markup = "auto-detect"
    phrases = ["United Arab Emirates", "Prime minister", "Internet caf\xc3\xa9", "\xD9\x85\xD9\x82\xD9\x87\xD9\x89 \xD8\xA5\xD9\x86\xD8\xAA\xD8\xB1\xD9\x86\xD8\xAA", "\xD8\xAA\xD9\x86\xD8\xB1\xD8\xAA\xD9\x86\xD8\xA5 \xD9\x89\xD9\x87\xD9\x82\xD9\x85"]
    phrases.each do |phrase|
      document_text = phrase
      results = parse_text_document(document_text, repository, markup)
      assert_equal 1, results.size, "Problem parsing #{phrase}"
    end
  end

  def test_redirect_target_and_sources
    misspelled_article = Article.find_by_title("Maria Theresa ov Austria")
    correct_article = Article.find_by_title("Maria Theresa of Austria")
    unrelated_article = Article.find_by_title("\xD8\xAA\xD9\x86\xD8\xB1\xD8\xAA\xD9\x86\xD8\xA5 \xD9\x89\xD9\x87\xD9\x82\xD9\x85")
    assert_equal correct_article, misspelled_article.redirect_target
    assert_not_equal unrelated_article, misspelled_article.redirect_target
    assert_nil correct_article.redirect_target

    assert_equal [misspelled_article], correct_article.redirect_sources
    assert_not_equal [unrelated_article], correct_article.redirect_sources
    assert_equal [], misspelled_article.redirect_sources
  end

  #Ensure that if article1 and article2 are mentioned in text, and article1 redirects to article2, then only article2 is found in the results
  def test_redirect_cleaning
    repository = Repository.find_by_abbreviation("af-uncyclopedia")
    markup = "auto-detect"
    misspelled_article = Article.find_by_title("Maria Theresa ov Austria")
    correct_article = Article.find_by_title("Maria Theresa of Austria")
    document_text_results_pairs = []
    document_text_results_pairs << [misspelled_article.title, [ [misspelled_article.title, misspelled_article] ] ] #Just checking the misspelled article exists
    document_text_results_pairs << [correct_article.title, [ [correct_article.title, correct_article] ] ] #Just checking the correctly spelled article exists
    document_text_results_pairs << ["#{misspelled_article.title} #{correct_article.title}", [ [correct_article.title, correct_article] ] ] #If both are unwikified, assert only the correct spelling is wikified
    document_text_results_pairs << ["[[#{correct_article.title}]] : #{misspelled_article.title} was born in", [  ] ] #If the correct spelling is wikified, don't wikify the incorrect spelling
    document_text_results_pairs.each do |document_text, expected_results|
      actual_results = parse_text_document(document_text, repository, markup)
      assert_equal expected_results, actual_results
    end
  end

  #Given a wikified singular, and an unwikified plural, assert that the plural is not detected as a result
  #This test is identical to test_redirect_cleaning except it uses lower cases
  def test_detect_redirected_plurals
    document_text = "a [[running back]] amongst running backs"
    expected_results = []
    actual_results = parse_text_document(document_text, @af_uncyclopedia, @auto_detect)
    assert_equal expected_results, actual_results, "Problem with redirects"
  end

  def test_handles_articles_without_redirect_targets
    maria_theresa_article = Article.find_by_title("Maria Theresa of Austria")
    document_text = "a [[running back]] amongst running backs was #{maria_theresa_article.title}"
    expected_results = [ [maria_theresa_article.title, maria_theresa_article] ]
    actual_results = nil
    assert_nothing_raised do
      actual_results = parse_text_document(document_text, @af_uncyclopedia, @auto_detect)
    end
    assert_equal expected_results, actual_results
  end

  def test_handles_underscores_in_wikified_text
    document_text = "I wish to underscore the fact that a [[running_back]] is a running back no matter what."
    expected_results = []
    actual_results = parse_text_document(document_text, @af_uncyclopedia, @auto_detect)
    assert_equal expected_results, actual_results
  end

  def parse_text_document(document_text, repository, markup)
    document = Article.new_document(document_text, repository, markup)
    return document.parse
  end

  def test_ignore_boring_phrases
    document_text = "the the the the the the"
    expected_results = []
    actual_results = parse_text_document(document_text, @af_uncyclopedia, @auto_detect)
    assert_equal expected_results, actual_results
  end

end

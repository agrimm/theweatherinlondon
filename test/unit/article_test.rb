require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < Test::Unit::TestCase
  fixtures :articles
  fixtures :repositories

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_clean_results
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
    syntax_test_pairs_duplicate = syntax_test_pairs.dup
    syntax_test_pairs_duplicate.each do |first_pair|
      syntax_test_pairs_duplicate.each do |second_pair|
        syntax_test_pairs << [first_pair[0] + second_pair[0], first_pair[1] + second_pair[1] ]
      end
    end
    syntax_test_pairs.each do |syntax_test_pair|
      unparsed_text = syntax_test_pair[0]
      parsed_text = syntax_test_pair[1]
      assert_equal parsed_text, Article.send(method_symbol, unparsed_text)
    end
  end

  def test_parse_existing_wiki_links
    wiki_text = "The rain in [[London]] is quite [[London#climate|wet]]"
    assert_equal ["London"], Article.parse_existing_wiki_links(wiki_text)
  end

  def test_nested_templates
    wiki_text = "abc {{def {{ghi}} jkl}} mno"
    assert_equal "abc  mno", Article.parse_templates(wiki_text)
  end

  def test_trickier_non_direct_links
    wiki_texts = ["start [[Image:wiki.png]]finish", "start[[Image:wiki.png|The logo of this [[wiki]]]] finish", "start[[:Image:wiki.png|The logo of this [[wiki]], which is the English Wikipedia]] finish"]
    wiki_texts.each do |wiki_text|
      assert_equal "start finish", Article.parse_non_direct_links(wiki_text)
      assert_equal "start finish", Article.parse_wiki_text(wiki_text)
    end
  end

  def test_no_side_effects_on_document_text
    document_text = "[[en:Wikipedia]]"
    original_document_text = document_text.dup
    repository = Repository.find_by_abbreviation("af-uncyclopedia")
    markup = "auto-detect"
    Article.parse_text_document(document_text, repository, markup)
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
      results = Article.parse_text_document(document_text, repository, markup)
      assert_equal expected_results, results
    end
  end
end

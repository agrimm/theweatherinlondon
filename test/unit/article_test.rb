require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < Test::Unit::TestCase
  fixtures :articles

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_clean_results
    article1 = Article.create!(:title=> "a", :uri=>"http://www.example.com/1")
    article2 = Article.create!(:title=> "b", :uri=>"http://www.exampel.com/2")
    identical_results = [ ["Winter Olympic", article1] , ["Winter Olympic", article2] ]
    cleaned_results = Article.clean_results(identical_results)
    assert identical_results.size == 2, "Wrong number of original items"
    assert cleaned_results.size == 1, "Wrong number of final items"
    containing_results = [ ["Winter Olympic Games", article1] , ["Winter Olympic", article2] ]
    cleaned_results = Article.clean_results(containing_results)
    assert containing_results.size == 2, "Wrong number of original items"
    assert cleaned_results.size == 1, "Wrong number of final items"
  end
end

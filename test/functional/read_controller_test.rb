require File.dirname(__FILE__) + '/../test_helper'
require 'read_controller'

# Re-raise errors caught by the controller.
class ReadController; def rescue_action(e) raise e end; end

class ReadControllerTest < Test::Unit::TestCase
  def setup
    @controller = ReadController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end

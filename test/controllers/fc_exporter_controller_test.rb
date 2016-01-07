require 'test_helper'

class FcExporterControllerTest < ActionController::TestCase
  test "should get pageLoad" do
    get :pageLoad
    assert_response :success
  end

end

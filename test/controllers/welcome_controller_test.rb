require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test 'be redirected to the pull request controller' do
    get welcome_index_url
    assert_response :redirect
  end
end

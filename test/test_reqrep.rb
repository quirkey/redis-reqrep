require 'minitest/autorun'
require 'mock_redis'
require 'mocha'

require File.expand_path('../reqrep', File.dirname(__FILE__))

class TestReqrep < MiniTest::Unit::TestCase
  include Reqrep

  Request.redis = Reply.redis = MockRedis.new

  def test_should_make_and_get_next
    request = Request.new(:index, {'content-type' => 'image/png'}, 'this is the body')
    assert_equal :request, request.message_type
    assert request.push
    assert request.id
    next_request = Request.next
    assert_equal request, next_request
  end

  def test_should_define_handler_on_app
    app = App.new
    app.add_handler :index do |request|
    end
    assert app.handlers
    assert_equal 1, app.handlers.length
  end

  def test_should_invoke_handler_with_a_request_object
    app = App.new
    request = Request.new :index
    requests = []
    app.add_handler :index do |request|
      requests << request
      "Response"
    end
    returned = app.invoke_handler :index, request
    assert returned.is_a?(Array)
    assert_equal 1, requests.length
    assert_equal :success, returned[0]
    assert_equal "Response", returned[2]
  end

  def test_should_use_handler_to_serve_request
  end

end

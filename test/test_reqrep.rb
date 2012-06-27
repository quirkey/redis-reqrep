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

  def test_should_invoke_handler_with_custom_return
    app = App.new
    request = Request.new :index, {'custom' => 'sup'}
    app.add_handler :index do |request|
      [:success, request.headers, nil]
    end
    returned = app.invoke_handler :index, request
    assert returned.is_a?(Array)
    assert_equal :success, returned[0]
    assert_equal "sup", returned[1]['custom']
    assert_equal nil, returned[2]
  end

  def test_should_use_handler_to_serve_request
    app = App.new
    request = Request.new :reverse, {}, "body"
    app.add_handler :reverse do |request|
      request.body.reverse
    end
    reply = app.handle_request(request)
    assert reply
    assert reply.is_a?(Reply)
    assert reply.id
    assert_equal request.id, reply.request_id
    assert_equal "success", reply.status
    assert_equal "ydob", reply.body
  end

  def test_should_return_not_found_reply_for_bad_request

  end

end

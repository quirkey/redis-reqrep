require 'minitest/autorun'
require 'mock_redis'
require 'mocha'

require File.expand_path('../reqrep', File.dirname(__FILE__))

class TestReqrep < MiniTest::Unit::TestCase
  include Reqrep

  Request.redis = Reply.redis = MockRedis.new

  def test_should_make_and_reply_to_request
    request = Request.new(:index, {'content-type' => 'image/png'}, 'this is the body')
    assert_equal :request, request.message_type
    assert request.push
    assert request.id
    next_request = Request.next
    assert_equal request, next_request
  end

end

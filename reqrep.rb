require 'redised'

module Reqrep

  class Message
    include Redised

    attr_writer :id
    attr_accessor :action, :headers, :body

    def self.find(id)
      message = new(
        redis.get("#{message_type}:#{id}:action"),
        redis.hgetall("#{message_type}:#{id}:headers"),
        redis.get("#{message_type}:#{id}:body")
      )
      message.id = id.to_i
      message
    end

    def initialize(action, headers = {}, body = nil)
      self.action = action.to_s
      self.headers = headers
      self.body = body
    end

    def ==(other)
      id == other.id && action == other.action
    end

    def self.message_type
      :message
    end

    def message_type
      self.class.message_type
    end

    def id
      @id ||= redis.incr "#{message_type}_ids"
    end

    def push
      store_message
      redis.rpush "request", id
    end

    def store_message
      redis.set "#{message_type}:#{id}:action", action
      redis.hmset "#{message_type}:#{id}:headers", *headers.flatten
      redis.set "#{message_type}:#{id}:body", body
    end

  end

  class Request < Message

    def self.next
      q, request_id = redis.blpop("request", 30)
      if request_id
        Request.find(request_id)
      else
        false
      end
    end

    def self.message_type
      :request
    end

  end

  class Reply < Message

    attr_accessor :request_id

    def self.next(request_id)
      q, reply_id = redis.blpop("reply:#{request_id}", 30)
      Reply.find(reply_id)
    end

    def self.message_type
      :reply
    end

    def push
      store_message
      redis.rpush "reply:#{request_id}", id
    end

  end

  def self.add_handler(action, &block)
    @handlers ||= {}
    @handlers[action] = block
  end

  def self.request(action, headers = {}, body = nil)

  end

  def self.serve
    request = Request.next
    if action = @handlers[request.action]
      reply = Reply.new(*action.call)
    else
    end
  end

end

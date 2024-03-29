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
      redis.hmset "#{message_type}:#{id}:headers", *headers.flatten if headers.any?
      redis.set "#{message_type}:#{id}:body", body
    end

    def reply
      q, reply_id = redis.blpop("reply:#{id}", 30)
      reply = Reply.find(reply_id)
      if reply
        reply.request_id = id
      end
      reply
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

    alias :status :action

    def self.message_type
      :reply
    end

    def push
      store_message
      redis.rpush "reply:#{request_id}", id
    end

  end

  class App
    attr_reader :handlers

    def initialize
      @handlers = {}
    end

    def add_handler(action, &block)
      @handlers[action.to_s] = block
    end

    alias :on :add_handler

    def has_handler?(action)
      @handlers.has_key?(action.to_s)
    end

    def invoke_handler(action, request)
      action = @handlers[action.to_s]
      begin
        returned = action.call(request)
        if returned.is_a?(Array) && returned.length == 3
          returned
        else
          [:success, {}, returned.to_s]
        end
      rescue => e
        [:error, request.headers, "Error: #{e}\n\n#{e.backtrace}"]
      end
    end

    def handle_request(request)
      if has_handler?(request.action)
        reply = Reply.new(*invoke_handler(request.action, request))
      else
        reply = Reply.new(:not_found)
      end
      reply.request_id = request.id
      reply.push
      reply
    end

    def serve
      request = Request.next
      handle_request(request) if request
    end

    def run!
      loop do
        serve
      end
    end

  end

  def self.request_and_wait_for_reply(action, headers = {}, body = nil)
    request = Request.new(action, headers, body)
    request.push
    request.reply
  end

end

require './config'

module BeforeYou
  class Backend
    KEEPALIVE_TIME = 15 # in seconds

    def initialize(app)
      @app     = app
      @clients = []

      uri = URI.parse('redis://localhost:6379')
      @redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)
      
      Thread.new do
        redis_sub = Redis.new(host: uri.host, port: uri.port, password: uri.password)
        redis_sub.subscribe(Location.redis_channel) do |on|
          on.message do |channel, msg|
            @clients.each do |ws|
              ws.send( JSON.generate({action: 'new', data: JSON.parse(msg) }) )
            end
          end
        end
      end
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })

        ws.on :open do |event|
          puts [:open, ws.object_id].inspect
          @clients << ws
        end

        ws.on :message do |event|
          puts [:message, event.data].inspect
          # @redis.publish(CHANNEL, sanitize(event.data))
          # @redis.publish(CHANNEL, event.data)
        end

        ws.on :close do |event|
          puts [:close, ws.object_id, event.code, event.reason].inspect
          @clients.delete(ws)
          ws = nil
        end

        # Return async Rack response
        ws.rack_response

      else
        @app.call(env)
      end
    end

  private

    # def sanitize(message)
    #   json = JSON.parse(message)
    #   json.each {|key, value| json[key] = ERB::Util.html_escape(value) }
    #   JSON.generate(json)
    # end

  end
end

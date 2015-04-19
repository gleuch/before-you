require './config'

module BeforeYou
  class Backend

    def initialize(app)
      @app, @clients, @redis_uri = app, [], URI.parse('redis://localhost:6379')
      @redis = Redis.new(host: @redis_uri.host, port: @redis_uri.port, password: @redis_uri.password)

      # New thread to listen for latest items
      Thread.new do
        redis_sub = Redis.new(host: @redis_uri.host, port: @redis_uri.port, password: @redis_uri.password)
        redis_sub.subscribe(Location.redis_channel) do |on|
          on.message do |channel, msg|
            @clients.each do |ws|
              ws.send( JSON.generate({action: 'latest', data: JSON.parse(msg)}) )
            end
          end
        end
      end
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: 15})

        ws.on :open do |event|
          @clients << ws
        end

        ws.on :message do |event|
          begin
            data = JSON.parse(event.data) rescue nil
            case data['action']
              when 'self'
                get_current_location(ws, env['REMOTE_ADDR'])
            end

          rescue
            nil
          end
        end

        ws.on :close do |event|
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

    def get_current_location(ws,ip)
      ip = '50.14.165.216' if ['::1','127.0.0.1'].include?(ip) # DEBUG

      loc = Location.where(ip_address: ip).first rescue nil
      return if loc.blank?

      # If location is completed, then return immediately
      if loc.completed?
        ws.send( JSON.generate( {action: 'self', data: loc.to_api} ) )

      # Otherwise subscribe to thread to get updates
      else
        Thread.new do
          redis_sub = Redis.new(host: @redis_uri.host, port: @redis_uri.port, password: @redis_uri.password)
          redis_sub.subscribe(loc.redis_channel) do |on|
            on.message do |channel, msg|
              ws.send( JSON.generate({action: 'self', data: JSON.parse(msg)}) )
            end
          end
        end
      end
    end
  end
end

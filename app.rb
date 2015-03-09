# encoding: UTF-8

# (C) 2015 Greg Leuch. All Rights Reserved
# License information: LICENSE.md


# START IT UP...

require 'sinatra/base'

module BeforeYou
  class App < Sinatra::Base
    configure do
      APP_ROOT = File.expand_path('.', File.dirname(__FILE__))
      DEBUG = false
      TIME_START = Time.now

      require "#{APP_ROOT}/config.rb"
      require 'sinatra/content_for'
      require 'sinatra/respond_with'

      helpers Sinatra::ContentFor
      register Sinatra::RespondWith

      register Sinatra::AssetPack
      assets {
        serve '/js',     from: 'app/js'        # Default
        serve '/css',    from: 'app/css'       # Default
        serve '/images', from: 'app/images'    # Default

        js :app, '/js/app.js', ['/js/vendor/**/*.js', '/js/lib/**/*.js', '/js/application.js']
        css :app, '/css/app.css', ['/css/screen.css']

        js_compression  :jsmin    # :jsmin | :yui | :closure | :uglify
        css_compression :sass   # :simple | :sass | :yui | :sqwish
      }


      # FLASH_TYPES = [:warning, :notice, :success, :error]
      # use Rack::Session::Cookie, key: 'beforeyou_rack_key', secret: '0hN0aft3ryu0plz1insi5t', path: '/', expire_after: 21600
      # set :sessions => true

      # --- I18N -------------------------------
      # register Sinatra::R18n
      # set :default_locale, 'en'
      # set :translations,   './i18n'
    end


    # About Page
    get '/about' do
      respond_to do |format|
        format.html { haml :'about.html', layout: :'layout.html' }
      end
    end


    # Connect
    get '/websocket/connect' do
    end


    # Homepage
    get '/' do
      # Get "you", based on your IP address
      @you = Location.where(ip_address: request.ip).first_or_create do |u|
        u.ip_address = request.ip
        u.useragent = request.user_agent
      end

      # Track the impression of "you"
      @you.impression!

      # Get the person before you
      @before_you = Location.latest.completed.first

      # Show them who was before them
      respond_to do |format|
        format.html { haml :'index.html', layout: :'layout.html' }
      end
    end

  end
end
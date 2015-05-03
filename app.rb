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

      require File.join(APP_ROOT, 'config.rb')

      if ENV['DEBUG'] == '1'
        require 'sinatra/reloader'
        register Sinatra::Reloader
        enable :reloader
      end

      require 'sinatra/content_for'
      require 'sinatra/respond_with'

      helpers Sinatra::ContentFor
      register Sinatra::RespondWith


      # --- ASSETS ------------------------------
      register Sinatra::AssetPack
      assets {
        serve '/js',     from: 'app/js'        # Default
        serve '/css',    from: 'app/css'       # Default
        serve '/images', from: 'app/images'    # Default

        js :app, '/js/app.js', ['/js/vendor/**/*.js', '/js/lib/**/*.js', '/js/three.min.js', '/js/application.js']
        css :app, '/css/app.css', ['/css/screen.css']

        js_compression  :jsmin    # :jsmin | :yui | :closure | :uglify
        css_compression :sass   # :simple | :sass | :yui | :sqwish
      }

      # --- SESSIONS ----------------------------
      # FLASH_TYPES = [:warning, :notice, :success, :error]
      # use Rack::Session::Cookie, key: 'beforeyou_rack_key', secret: '0hN0aft3ryu0plz1insi5t', path: '/', expire_after: 21600
      # set :sessions => true


      # --- I18N --------------------------------
      # register Sinatra::R18n
      # set :default_locale, 'en'
      # set :translations,   './i18n'


      # --- ACTIONS -----------------------------
      require File.join(APP_ROOT, 'lib/actions.rb')

      before do
        @meta_page_title = 'b4u:today'
        @meta_page_desc = ''
      end

    end
  end
end
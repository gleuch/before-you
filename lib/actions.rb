module BeforeYou
  class App < Sinatra::Base

    # About/credits
    get '/about' do
      respond_to do |format|
        format.html {
          @meta_page_title = "about b4u:today"

          haml :'about.html', layout: :'layout.html'
        }
      end
    end

    # Show previous day
    get '/:year/:month/:day' do
      date_str = [:year,:month,:day].map{|v| params[v]}
      @request_date = Date.parse(date_str.join('-'))

      respond_to do |format|
        format.html {
          @meta_page_title = "b4u:" << @request_date.strftime('%d %b %Y')

          @before_you = Location.on(@request_date).completed.limit(10)

          haml :'date.html', layout: :'layout.html'
        }
      end
    end


    # Homepage
    get '/' do
      # Get "you", based on your IP address
      ip = request.ip
      ip = '50.14.165.216' if ['::1','127.0.0.1'].include?(ip) # DEBUG

      @you = Location.where(ip_address: ip).first_or_create do |u|
        u.ip_address = ip
        u.useragent = request.user_agent
      end

      # Show them who was before them
      respond_to do |format|
        format.html {
          # Track the impression of "you"
          @you.impression!

          # Get the person before you
          @before_you = Location.latest.completed.limit(10)

          haml :'index.html', layout: :'layout.html'
        }
      end
    end

  end
end
module BeforeYou
  class App < Sinatra::Base

    # About/credits
    get '/about' do
      respond_to do |format|
        format.html {
          @meta_page_title = 'about b4u:today'

          haml :'about.html', layout: :'layout.html'
        }
      end
    end

    # Show previous day
    get %r{/(2015)/(\d{2})/(\d{2})} do |y,m,d|
      date_str = [y,m,d].join('-')
      @request_date = Date.parse(date_str)

      respond_to do |format|
        format.html {
          @meta_page_title = 'b4u:' << @request_date.strftime('%d %b %Y')

          @before_you = Location.on(@request_date).latest.completed.limit(10)
          @before_you_day_count = Location.on(@request_date).completed.count

          haml :'date.html', layout: :'layout.html'
        }
      end
    end


    # Homepage
    get '/' do
      # Get "you", based on your IP address
      ip = request.ip
      ip = [rand(255),rand(255),rand(255),rand(255)].join('.') if ['::1','127.0.0.1'].include?(ip) # DEBUG

      @request_date = Time.now.utc.to_date

      @you = Location.where(ip_address: ip).first_or_create do |u|
        u.ip_address = ip
        u.useragent = request.user_agent
      end

      # Show them who was before them
      respond_to do |format|
        format.html {
          @meta_page_title = 'b4u:today'
          
          # Track the impression of "you"
          @you.impression!

          # Get the person before you
          @before_you = Location.on(@request_date).latest.completed.limit(100)
          @before_you_day_count = Location.on(@request_date).completed.count

          haml :'index.html', layout: :'layout.html'
        }
      end
    end

  end
end
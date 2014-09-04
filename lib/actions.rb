# Homepage
get '/' do
  # Get "you", based on your IP address
  @you = Location.where(ip_address: request.location).first_or_create do |u|
    u.ip_address = request.ip
    u.useragent = request.user_agent
  end

  @you.impression!

  # Get the person before you
  @before_you = Location.latest.completed.first

  # Show them who was before them
  haml :index
end
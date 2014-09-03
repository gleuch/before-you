# Homepage
get '/' do
  # Get "you", based on your IP address
  @you = Location.where(ip_address: request.location).first_or_create do |u|
    u.ip_address = request.location
    # u.useragent = request.useragent
  end

  # Track
  # impressionist(@you)

  # Get the person before you
  @before_you = Location.latest.completed.first

  # Show them who was before them
  haml :index
end
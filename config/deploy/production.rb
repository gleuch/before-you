# PRODUCTION CONFIG
set :rails_env, :production

role :app, %w{b4u.today}
role :web, %w{b4u.today}
role :db,  %w{b4u.today}

server 'b4u.today', user: 'b4u', roles: %w{web app db}

set :deploy_to, '/home/b4u/b4u.today'


# WHENEVER
# set :whenever_roles, -> { [:db] }
# set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:production)}" }

# SIDEKIQ
set :sidekiq_processes, 2
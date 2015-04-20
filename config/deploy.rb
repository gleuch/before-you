lock '3.4.0'

set :application, 'BeforeYou'
set :repo_url, 'git@github.com:gleuch/before-you.git'
set :rvm_type, :user
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :scm, :git
set :format, :pretty
set :log_level, :debug

set :linked_files, %w{config.ru config/config.yml config/database.yml config/sidekiq.yml}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

set :keep_releases, 5

# --- DEPLOY ------------------------------------------------------------------
namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
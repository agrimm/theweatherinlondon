#require 'mongrel_cluster/recipes'

set :application, "weatherinlondon"
set :repository,  "git@github.com:agrimm/theweatherinlondon.git"

default_run_options[:pty] = true
set :branch, "master"

set :user, "sample_user_name"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/#{user}/#{application}"

set :deploy_via, :copy

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git

#No mongrel cluster available
#set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"

set :symlink_commands, "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml"

role :app, "theweatherinlondon.com"
role :web, "theweatherinlondon.com"
role :db,  "theweatherinlondon.com", :primary => true

#Courtesy of paulhammond.org and also pragmatic deployment, how to deal with database.yml and friends
desc "link in production database credentials, and other similar files" 
task :after_update_code do
  run "#{symlink_commands}"
end

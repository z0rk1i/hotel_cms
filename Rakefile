require_relative "config/environment"
require "rake"

DB = ActiveRecord::Base.connection_db_config.configuration_hash

def psql(*args)
  cmd = [ "psql", "-h", DB.fetch(:host, "/tmp"), "-p", DB.fetch(:port, 5432).to_s, "-d", DB[:database] ]
  cmd += [ "-U", DB[:username] ] if DB[:username]
  system(*cmd, *args) || abort("psql failed")
end

namespace :db do
  desc "Load schema from db/structure.sql"
  task :schema_load do
    psql("-f", File.join(APP_ROOT, "db", "structure.sql"))
    puts "Schema loaded into #{DB[:database]}"
  end

  desc "Dump schema to db/structure.sql"
  task :schema_dump do
    cmd = [ "pg_dump", "-h", DB.fetch(:host, "/tmp"), "-p", DB.fetch(:port, 5432).to_s, "-d", DB[:database], "-s" ]
    cmd += [ "-U", DB[:username] ] if DB[:username]
    system(*cmd, out: File.join(APP_ROOT, "db", "structure.sql")) || abort("pg_dump failed")
    puts "Schema dumped to db/structure.sql"
  end

  desc "Seed the database"
  task :seed do
    load File.join(APP_ROOT, "db", "seeds.rb")
    puts "Seeds applied"
  end

  desc "Prepare test database (drop, create, load schema)"
  task :test_prepare do
    ENV["APP_ENV"] = "test"
    require_relative "config/environment"
    ActiveRecord::Base.connection_pool.disconnect!
    ActiveRecord::Base.connection.drop_database(ActiveRecord::Base.connection_db_config.database)
    ActiveRecord::Base.connection.create_database(ActiveRecord::Base.connection_db_config.database)
    Rake::Task["db:schema_load"].invoke
  end
end

desc "Build Tailwind CSS into public/assets/tailwind.css"
task :tailwind do
  input = File.join(APP_ROOT, "app", "assets", "tailwind", "application.css")
  output = File.join(APP_ROOT, "public", "assets", "tailwind.css")
  FileUtils.mkdir_p(File.dirname(output))
  system("bundle exec tailwindcss -i #{input} -o #{output} --minify") || abort("tailwind build failed")
  puts "Built #{output}"
end

desc "Run the test suite"
task :spec do
  system("bundle exec rspec") || abort("specs failed")
end

task default: :spec

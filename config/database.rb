db_config_path = File.join(APP_ROOT, "config", "database.yml")
configs = YAML.safe_load(ERB.new(File.read(db_config_path)).result, aliases: true)
defaults = configs.fetch("default", {})
config = defaults.merge(configs.fetch(ENV["APP_ENV"] || "development"))

ActiveRecord::Base.establish_connection(config)
ActiveRecord::Base.logger = Logger.new($stdout) if ENV["DEBUG_SQL"] == "1"

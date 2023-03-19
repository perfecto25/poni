# pp!

require "logger"
require "option_parser"
require "inotify"
require "./watcher"
require "colorize"
require "yaml"

module Poni
  extend self

  VERSION = "0.1.3"
  cfgfile = "/etc/poni/config.yml"

  OptionParser.parse do |parser|
    parser.banner = "Poni - inotify rsync daemon"
    parser.on("-c CONFIG", "--config=CONFIG", "path to config file") { |config| cfgfile = config }
    parser.on "-h", "--help", "Show help" do
      puts parser
      exit
    end
    parser.on "-v", "--version", "Show version" do
      puts VERSION
      exit
    end
    parser.invalid_option do |flag|
      STDERR.puts "ERROR: #{flag} is not a valid option."
      STDERR.puts parser
      exit(1)
    end
  end

  abort "config file is missing", 1 if !File.file? cfgfile

  begin
    cfg = YAML.parse(File.read(cfgfile)).as_h
  rescue exception
    abort "unable to read config file", 1
  end

  # logging options
  begin
    if cfg.has_key?("log_path")
      log_path = cfg["log_path"].as_s
    else
      log_path = "stdout"
    end

    if log_path != "stdout"
      file = File.new(log_path, "a")
      writer = IO::MultiWriter.new(file, STDOUT)
      log = Logger.new(writer, level: Logger::INFO)
    else
      log = Logger.new(STDOUT, level: Logger::INFO)
    end
  rescue exception
    abort exception, 1
  end

  channel = Channel(Bool).new

  # # package default values, if not present in config.yaml
  DEFAULTS = {
    "port":       22,
    "recurse":    false,
    "rsync_opts": "azP",
    "interval":   10,
  }

  def get_val(lookup, sync, data, cfg, log)
    if data.as_h.has_key?(lookup)
      return data[lookup]?
    end

    if cfg.has_key?("defaults")
      if cfg["defaults"].as_h.has_key?(lookup)
        return cfg["defaults"][lookup]?
      end
    end

    if DEFAULTS.has_key?(lookup)
      return DEFAULTS[lookup]?
    end

    # exit if cant find lookup value
    log.error("unable to find value for sync name: #{sync}, key: #{lookup}")
    abort "unable to find value for sync name: #{sync}, key: #{lookup}", 1
  end

  # parse each sync config and spawn into background
  begin
    # create a Hash map of all source_paths > goes to Watcher to create unique watch for each src path
    map = Hash(String, Array(Hash(String, String))).new

    # get sync values, if no value then use default fallback
    cfg["sync"].as_h.each do |sync, data|
      source_path = (get_val "source_path", sync, data, cfg, log).to_s
      remote_host = (get_val "remote_host", sync, data, cfg, log).to_s
      remote_path = (get_val "remote_path", sync, data, cfg, log).to_s
      remote_user = (get_val "remote_user", sync, data, cfg, log).to_s
      priv_key = (get_val "priv_key", sync, data, cfg, log).to_s
      port = (get_val "port", sync, data, cfg, log).to_s
      recurse = (get_val "recurse", sync, data, cfg, log).to_s
      rsync_opts = (get_val "rsync_opts", sync, data, cfg, log).to_s
      interval = (get_val "interval", sync, data, cfg, log).to_s

      # for every source_path, create array of remote_paths and related data
      arr = [] of Hash(String, String)
      data = {
        "remote_host" => remote_host,
        "remote_path" => remote_path,
        "remote_user" => remote_user,
        "priv_key"    => priv_key,
        "port"        => port,
        "recurse"     => recurse,
        "rsync_opts"  => rsync_opts,
        "interval"    => interval,
      }

      arr << data

      if !map.has_key?(source_path)
        map[source_path] = arr
      else
        map[source_path] << data
      end

      # map[sync] << {"remote_host": remote_host, "remote_path": remote_path, "remote_user": remote_user, "priv_key": priv_key}
      # start Watcher
      # Watcher.spawn_watcher(sync.to_s, remote_user.to_s, remote_host.to_s, remote_path.to_s,
      #  rsync_opts.to_s, priv_key.to_s, port.to_s.to_i, interval.to_s.to_i, recurse_bool, log)
    end

    # iterate every source_path in Map, and spawn a watcher
    map.each do |src_path, data|
      Watcher.spawn_watcher(src_path, data, log)
    end
  rescue exception
    log.fatal(exception)
    abort "error running sync: #{exception}", 1
  end

  while 1 == 1
    if channel.closed?
      exit
    else
      puts channel.receive
    end
  end
end # # module

# pp!
require "option_parser"
require "inotify"
require "./watcher"
require "./scheduler"
require "./log"
require "colorize"
require "yaml"

module Poni
  extend self
  VERSION = "0.1.4"

  cfgfile = "/etc/poni/config.yml"

  OptionParser.parse do |parser|
    parser.banner = "Poni - inotify rsync daemon"
    parser.on("-c CONFIG", "--config=CONFIG", "path to config file") { |config| cfgfile = config }
    parser.on "-h", "--help", "Show help" do
      STDOUT.puts parser
      exit(0)
    end
    parser.on "-v", "--version", "Show version" do
      STDOUT.puts VERSION
      exit(0)
    end
    parser.invalid_option do |flag|
      STDERR.puts "ERROR: #{flag} is not a valid option."
      STDERR.puts parser
      exit(1)
    end
  end

  abort "config file is missing", 1 if !File.file? cfgfile

  begin
    cfg = YAML.parse(File.read(cfgfile))
  rescue exception
    abort "unable to read config file", 1
  end

  log = init_log(cfg)
  channel = Channel(String).new

  # # package default values, if not present in config.yaml
  DEFAULTS = {
    "port":       22,
    "recurse":    false,
    "rsync_opts": "azP",
    "interval":   10,
    "simulate":   true,
  }

  def get_val(lookup, sync, data, cfg, log)
    if (_data_lookup = data.dig?(lookup))
      return _data_lookup
    end

    if (_defaults_lookup = cfg.dig?("defaults", lookup))
      return _defaults_lookup
    end

    if DEFAULTS.has_key?(lookup)
      return DEFAULTS[lookup]?
    end

    # exit if cant find lookup value
    log.error { "unable to find value for sync name: #{sync}, key: #{lookup}" }
    abort "unable to find value for sync name: #{sync}, key: #{lookup}", 1
  end

  # parse each sync config and spawn into background
  begin
    # create a Hash map of all source_paths > goes to Watcher to create unique watch for each src path
    map = Hash(String, Array(Hash(String, String))).new
    sync_now = Hash(String, Bool).new # src_path[true/false]

    # get sync values, if no value then use default fallback
    cfg["sync"].as_h.each do |sync, data|
      source_path = get_val("source_path", sync, data, cfg, log).to_s
      remote_host = get_val("remote_host", sync, data, cfg, log).to_s
      remote_path = get_val("remote_path", sync, data, cfg, log).to_s
      remote_user = get_val("remote_user", sync, data, cfg, log).to_s
      priv_key = get_val("priv_key", sync, data, cfg, log).to_s
      port = get_val("port", sync, data, cfg, log).to_s
      recurse = get_val("recurse", sync, data, cfg, log).to_s
      rsync_opts = get_val("rsync_opts", sync, data, cfg, log).to_s
      interval = get_val("interval", sync, data, cfg, log).to_s
      simulate = get_val("simulate", sync, data, cfg, log).to_s

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
        "simulate"    => simulate,
      }

      arr << data

      if !map.has_key?(source_path)
        map[source_path] = arr
      else
        map[source_path] << data
      end
    end

    # CREATE WATCHERS and SYNC SCHEDULERS
    # iterate every source_path in Map, and spawn a watcher
    map.each do |src_path, sync_data|
      Watcher.spawn_watcher(src_path, sync_data, channel, log)
      sync_now[src_path] = false
      Scheduler.start_sched(src_path, sync_data, sync_now, log)
    end

  # CREATE SCHEDULERS
  rescue exception
    log.error { exception }
    abort "error running sync: #{exception}", 1
  end # begin

  while 1 == 1
    if channel.closed?
      exit
    else
      channel_data = channel.receive
      path = channel_data.split(",")[1].strip
      sync_now[path] = true
    end
  end
end # # module

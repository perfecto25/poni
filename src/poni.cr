require "logger"
require "option_parser"
require "totem"
require "inotify"
require "./watcher"

module Poni
  VERSION = "0.1.1"
  log = Logger.new(STDOUT, level: Logger::INFO)
  cfgfile = "/etc/poni/config.yml"

  OptionParser.parse do |parser|
    parser.banner = "Poni - inotify rsync daemon"
    parser.on("-c CONFIG", "--config=CONFIG", "path to config file") { |config| cfgfile=config }
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
    totem = Totem.from_file cfgfile
  rescue exception
    log.error("unable to open config file")
    abort "unable to open config file", 1
  end

  channel = Channel(Bool).new
  recursive = false 
  
  begin
    totem.get("sync").as_h.keys.each do |key|
      log.error("#{key} source file or directory is missing") if !File.exists? key
      abort "#{key} source file or directory is missing", 1 if !File.exists? key

      totem.set_default("sync.#{key}.interval", 3)
      totem.set_default("sync.#{key}.rsync_opts", "azP")
      totem.set_default("sync.#{key}.port", 22)
      totem.set_default("sync.#{key}.recurse", "false")

      begin
        remote_path = totem.get("sync.#{key}.remote_path").as_s
        remote_host = totem.get("sync.#{key}.remote_host").as_s
        remote_user = totem.get("sync.#{key}.remote_user").as_s
        priv_key = totem.get("sync.#{key}.priv_key").as_s
        interval = totem.get("sync.#{key}.interval").as_i
        rsync_opts = totem.get("sync.#{key}.rsync_opts").as_s
        port = totem.get("sync.#{key}.port").as_i
        recurse = totem.get("sync.#{key}.recurse")
  
      rescue exception
        log.error("unable to get config values: #{exception}")
        abort "unable to get config values: #{exception}", 1
      end
      
      if recurse == "true" || recurse == true
          recursive = true 
      elsif recurse == "false" || recurse == false
          recursive = false
      end
      
      Watcher.spawn_watcher(key, remote_user, remote_host, remote_path, rsync_opts, priv_key, port, interval, recursive)
    end ## key
  rescue exception
    log.error(exception)
    abort "error running sync: #{exception}", 1
  end 

  while 1 == 1
    if channel.closed?
      exit
    else
      puts channel.receive
    end 
  end


end ## module

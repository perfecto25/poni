#pp!

require "logger"
require "option_parser"
#require "totem"
require "inotify"
require "./watcher"
require "colorize"
require "yaml"



module Poni
  VERSION = "0.1.2"
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
    cfg = YAML.parse(File.read(cfgfile)).as_h    
  rescue exception
    abort "unable to read config file", 1
  end


  puts cfg["defaults"]["remote_host"]

  ## logging options
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

  # parse each sync config and spawn into background
  begin
    # get sync values, if no value then use default fallback
    cfg["sync"].as_h.each do | sync, val |
      remote_host = val.as_h.fetch("remote_host", cfg["defaults"]["remote_host"])
      remote_path = val.as_h.fetch("remote_path", cfg["defaults"]["remote_path"])
      remote_user = val.as_h.fetch("remote_user", cfg["defaults"]["remote_user"])
      priv_key = val.as_h.fetch("priv_key", cfg["defaults"]["priv_key"])
      port = val.as_h.fetch("port", cfg["defaults"]["port"])
      recurse = val.as_h.fetch("recurse", cfg["defaults"]["recurse"])
      rsync_opts = val.as_h.fetch("rsync_opts", cfg["defaults"]["rsync_opts"])
      interval = val.as_h.fetch("interval", cfg["defaults"]["interval"])

      # default recurse 
      recurse_bool = false
      
      if recurse == "true" || recurse == true
        recurse_bool = true
      elsif recurse == "false" || recurse == false
        recurse_bool = false
      end

      # start Watcher 
      Watcher.spawn_watcher(sync.to_s, remote_user.to_s, remote_host.to_s, remote_path.to_s, 
        rsync_opts.to_s, priv_key.to_s, port.to_s.to_i, interval.to_s.to_i, recurse_bool, log)

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


end ## module

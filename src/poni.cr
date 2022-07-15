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


  if cfg.has_key?("defaults")
    defaults = cfg["defaults"].as_h
  end
#  defaults = cfg["defaults"]
  puts typeof(defaults)
#  defaults = cfg.fetch("defaults")
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

#  puts defaults["remote_path"]

  # parse each sync config and spawn into background
  begin
    
    syncs = cfg["sync"].as_h

    syncs.each do | sync, val |
      v = val.as_h
#      puts "v #{v}"
#      puts typeof(v)
      puts defaults
      puts typeof(defaults)
      #a = v.fetch("remote_host", defaults)
      default_remote_host = defaults.fetch("remote_host", "")
      remote_host = v.fetch("remote_host", default_remote_host)
      # remote_path = v.fetch("remote_path", defaults["remote_path"])
      # remote_user = v.fetch("remote_user", defaults["remote_user"])
      # priv_key = v.fetch("priv_key", defaults["priv_key"])
      # port = v.fetch("port", defaults["port"])
      # recurse = v.fetch("recurse", defaults["recurse"])
      # rsync_opts = v.fetch("rsync_opts", defaults["rsync_opts"])
      # interval = v.fetch("interval", defaults["interval"])

      # if recurse == "true" || recurse == true
      #   recursive = true 
      # elsif recurse == "false" || recurse == false
      #   recursive = false
      # end

#      puts "recursive #{recursive}"


    end
  rescue exception
    log.fatal(exception)
    abort "error running sync: #{exception}", 1
  end



 # puts remote_path
  begin
    puts "test"
  #       # get YAML config values
  #       begin
  #         puts "sync.#{key}.remote_path".colorize.red
  #         remote_path = totem.get("sync.#{key}.remote_path").as_s
  #         remote_host = totem.get("sync.#{key}.remote_host").as_s
  #         remote_user = totem.get("sync.#{key}.remote_user").as_s
  #         priv_key = totem.get("sync.#{key}.priv_key").as_s
  #         interval = totem.get("sync.#{key}.interval").as_i
  #         rsync_opts = totem.get("sync.#{key}.rsync_opts").as_s
  #         port = totem.get("sync.#{key}.port").as_i
  #         recurse = totem.get("sync.#{key}.recurse")
  #       rescue exception
  #         log.fatal("unable to get config values: #{exception}")
  #         abort "unable to get config values: #{exception}", 1
  #       end

  #     end # if value.size < 1

#      log.error("#{key} source file or directory is missing") if !File.exists? key
#      abort "#{key} source file or directory is missing", 1 if !File.exists? key
      
  
      
      # if recurse == "true" || recurse == true
      #     recursive = true 
      # elsif recurse == "false" || recurse == false
      #     recursive = false
      # end
      # puts "interval #{interval}"
      # puts "recurse #{recurse}"
      # puts "#{remote_user}@#{remote_host}:/#{remote_path}"
      
      # Watcher.spawn_watcher(key, remote_user, remote_host, remote_path, rsync_opts, priv_key, port, interval, recursive, log)
    
      # puts "-------------------"
    #end ## key
  rescue exception
   # log.fatal(exception)
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

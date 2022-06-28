require "logger"
require "option_parser"
require "totem"
require "inotify"
require "./watcher"
require "colorize"

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
    totem = Totem.from_file cfgfile
  rescue exception
    abort "unable to open config file", 1
  end

  channel = Channel(Bool).new
  recursive = false 

  # configure logging
  totem.set_default("log", "stdout")
  log_path = totem.get("log").as_s
  begin
    if log_path != "stdout"
      file = File.new(log_path, "a")
      writer = IO::MultiWriter.new(file, STDOUT)
      log= Logger.new(writer, level: Logger::INFO)
    else
      log = Logger.new(STDOUT, level: Logger::INFO)
    end
  rescue exception
    abort exception, 1
  end

  # get Global values
  totem.set_defaults({
    "remote_path" => "",
    "remote_host" => "",
    "remote_user" => "",
    "interval" => 3,
    "port" => 22,
    "recurse" => "false",
    "rsync_opts" => "azP"
  })

#  remote_path = totem.get("remote_path").as_s

 # puts remote_path
  begin
    totem.get("sync").as_h.each do |key, value|
      puts key
      puts value
      ## if key is set to pick up global variables
      if value.size < 1
        puts "GLOBAL"
        begin
          remote_path = totem.get("remote_path").as_s
          remote_host = totem.get("remote_host").as_s
          remote_user = totem.get("remote_user").as_s
          priv_key = totem.get("priv_key").as_s
          interval = totem.get("interval").as_i
          rsync_opts = totem.get("rsync_opts").as_s
          port = totem.get("port").as_i
          recurse = totem.get("recurse")
        rescue exception
          log.fatal("unable to get config values: #{exception}")
          abort "unable to get config values: #{exception}", 1
        end  
      else
        puts "NOT GLOBAL"
        ## get custom values for each sync
        totem.set_default("sync.#{key}.interval", 3)
        totem.set_default("sync.#{key}.rsync_opts", "azP")
        totem.set_default("sync.#{key}.port", 22)
        totem.set_default("sync.#{key}.recurse", "false")

        # get YAML config values
        begin
          puts "sync.#{key}.remote_path".colorize.red
          remote_path = totem.get("sync.#{key}.remote_path").as_s
          remote_host = totem.get("sync.#{key}.remote_host").as_s
          remote_user = totem.get("sync.#{key}.remote_user").as_s
          priv_key = totem.get("sync.#{key}.priv_key").as_s
          interval = totem.get("sync.#{key}.interval").as_i
          rsync_opts = totem.get("sync.#{key}.rsync_opts").as_s
          port = totem.get("sync.#{key}.port").as_i
          recurse = totem.get("sync.#{key}.recurse")
        rescue exception
          log.fatal("unable to get config values: #{exception}")
          abort "unable to get config values: #{exception}", 1
        end

      end # if value.size < 1

      log.error("#{key} source file or directory is missing") if !File.exists? key
      abort "#{key} source file or directory is missing", 1 if !File.exists? key
      
  
      
      if recurse == "true" || recurse == true
          recursive = true 
      elsif recurse == "false" || recurse == false
          recursive = false
      end
      puts "interval #{interval}"
      puts "recurse #{recurse}"
      puts "#{remote_user}@#{remote_host}:/#{remote_path}"
      
      Watcher.spawn_watcher(key, remote_user, remote_host, remote_path, rsync_opts, priv_key, port, interval, recursive, log)
    
      puts "-------------------"
    end ## key
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

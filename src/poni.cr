require "logger"
require "option_parser"
require "totem"
require "./watcher"
require "./worker"

module Poni
  VERSION = "0.1.0"

  log = Logger.new(STDOUT, level: Logger::INFO)
  cfile = "/etc/poni/config.yml"

  OptionParser.parse do |parser|
    parser.banner = "Poni - inotify rsync daemon"
    parser.on("-c CONFIG", "--config=CONFIG", "Specifies the name to salute") { |config| cfile=config }
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

  abort "config file is missing", 1 if !File.file? cfile
  
  begin
    totem = Totem.from_file cfile
  rescue exception
    log.error("unable to open config file")
    abort "unable to open config file", 1
  end

  channel = Channel(String).new

  begin
    totem.get("sync").as_h.keys.each do |key|

      log.error("#{key} source file or directory is missing") if !File.exists? key
      abort "#{key} source file or directory is missing", 1 if !File.exists? key

      totem.set_default("sync.#{key}.interval", 3)
      totem.set_default("sync.#{key}.rsync_opts", "azP")
      totem.set_default("sync.#{key}.port", 22)

      interval = totem.get("sync.#{key}.interval").as_i
      rsync_opts = totem.get("sync.#{key}.rsync_opts").as_s
      port = totem.get("sync.#{key}.port").as_i

      begin
        remote_path = totem.get("sync.#{key}.remote_path").as_s
        remote_host = totem.get("sync.#{key}.remote_host").as_s
        remote_user = totem.get("sync.#{key}.remote_user").as_s
        priv_key = totem.get("sync.#{key}.priv_key").as_s
      rescue exception
        log.error("unable to get config values: #{exception}")
        abort "unable to get config values: #{exception}", 1
      end
      
      Worker.spawn_worker(key, remote_user, remote_host, remote_path, rsync_opts, priv_key, port, interval)

    end
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


end

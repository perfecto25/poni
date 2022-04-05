require "logger"
require "option_parser"
require "./watcher"
require "./worker"
require "./config"

# https://github.com/Dlacreme/spy/blob/master/src/watcher.cr

module Poni
  VERSION = "0.1.0"

  log = Logger.new(STDOUT, level: Logger::INFO)
  cfile = "/etc/poni/config.yml"

  OptionParser.parse do |parser|
    parser.banner = "poni"
    parser.on("-c CONFIG", "--config=CONFIG", "Specifies the name to salute") { |config| cfile=config }
  
    
    parser.on "-h", "--help", "Show help" do
      puts parser
      exit
    end
  end

  puts "#{cfile}"
  abort "config file is missing", 1 if !File.file? cfile



  #conf = Config.load_from_yml_file("./spy.yml")

  dst_host = "qbtm-uat"
  src_path = "/tmp/file"
  dst_path = "/tmp/file"

  # begin
  #   YAML.parse(File.read(cfile)).each do |data|
  #     puts data
  #   end
  # rescue exception
  #   puts "unable to parse #{cfile}"
  #   exit
  # end


  yaml = File.open(cfile) { |file| YAML.parse(file) }
  puts yaml.class                         # => YAML::Any
  hash = yaml.as_h
  hash["sync"].each do |h|
    puts h
  end

#  conf = Config.load_from_yml_file("./config.yml")


#  log.info("#{conf["sync"]}")

#  puts typeof(conf)

  
  channel = Channel(Int32).new  
 
  Worker.spawn_worker(src_path, dst_host, dst_path)

  while 1 == 1
    if channel.closed?
      exit
    else
      puts channel.receive
    end 
	end


  #sleep 60.seconds
 # watcher.close

end

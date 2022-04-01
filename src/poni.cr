require "./watcher"
require "./worker"


# https://github.com/Dlacreme/spy/blob/master/src/watcher.cr

module Poni
  VERSION = "0.1.0"

  #conf = Config.load_from_yml_file("./spy.yml")

  dst_host = "qbtm-uat"
  src_path = "/tmp/file"
  dst_path = "/tmp/file"
  
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

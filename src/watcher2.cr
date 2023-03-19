require "logger"
require "inotify"
require "schedule"


module Poni::Watcher
  extend self
  
  def spawn_watcher(src_path, remote_user, remote_host, remote_path, rsync_opts, priv_key, port, interval, recurse_bool, log)
    channel = Channel(String).new
    log.info("watching #{src_path}")
    
    ## rsync flag, if true will fire off an rsync
    sync_now = false

    spawn do
      begin
        Inotify.watch src_path, recurse_bool do |event| 
          log.info("file modified: #{event.name}, source path: #{src_path}")
          sync_now = true
          Fiber.yield        
        end ## event        
      rescue exception
        log.error(exception)
        next
      end
    end ## spawn

    ## check for any changes to src_path every interval seconds, rsync if changed
    Schedule.every(interval.seconds) do
      if sync_now 
          log.info("rsyncing #{src_path} to #{remote_path}")
          stdout = IO::Memory.new
          stderr = IO::Memory.new
          begin
            if remote_host == "localhost" || remote_host == "127.0.0.1" 
              command = "rsync -#{rsync_opts} #{src_path} #{remote_path}/"
            else
              puts "rsync -e 'ssh -p#{port} -i #{priv_key}' -#{rsync_opts} #{src_path} #{remote_user}@#{remote_host}:/#{remote_path}"
              command = "rsync -e 'ssh -p#{port} -i #{priv_key}' -#{rsync_opts} #{src_path} #{remote_user}@#{remote_host}:/#{remote_path}"
            end 

            exit_code = Process.run(command, shell: true, output: stdout, error: stderr).exit_code
      
            if exit_code != 0 
              log.error("error syncing #{src_path} to #{remote_host}:#{remote_path}: #{stderr}")
            end
          rescue exception 
            log.error(exception)
          end ## begin 
      end

      ## end of rsync cycle
      sync_now = false 
    end
    
  end ## def
end ## module

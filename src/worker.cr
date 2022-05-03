require "logger"
#require "./watcher"
require "inotify"

module Poni::Worker
  extend self
  
  def spawn_worker(src_path, remote_user, remote_host, remote_path, rsync_opts, priv_key, port, interval, recurse)
    log = Logger.new(STDOUT, level: Logger::DEBUG)  
    spawn do
      begin
        Inotify.watch src_path, recurse do |event| 
          log.info("#{src_path} modified, syncing to #{remote_host}:#{remote_path} after #{interval} seconds")
          sleep interval

          stdout = IO::Memory.new
          stderr = IO::Memory.new
  
          if remote_host == "localhost" || remote_host == "127.0.0.1" 
            command = "rsync -#{rsync_opts} #{src_path} #{remote_path}/"
          else
            command = "rsync -e 'ssh -p#{port} -i #{priv_key}' -#{rsync_opts} #{src_path} #{remote_user}@#{remote_host}:/#{remote_path}"
          end 

          exit_code = Process.run(command, shell: true, output: stdout, error: stderr).exit_code
      
          if exit_code != 0 
            log.error("error syncing #{src_path} to #{remote_host}:#{remote_path}: #{stderr}")
          end 
          Fiber.yield        
        end # event

      rescue exception
        log.error(exception)
        next
      end

    end # spawn
  end
end # module


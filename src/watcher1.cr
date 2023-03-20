require "logger"
require "inotify"
# require "schedule"
require "tasker"

module Poni::Watcher
  extend self



  def spawn_watcher(src_path, data, log, channel)
    log.info("watching #{src_path}")

    recurse_bool = false
    # sync_now = Bool.new
    sync_now = 0 # rsync flag, if true will fire off an rsync

    # if multiple remote_paths for same source_path, a single recurse=true means all recurse=true
    data.each do |remote|
      if remote["recurse"] == "true" || remote["recurse"] == true
        recurse_bool = true
      end
    end

    spawn do
      begin
        Inotify.watch src_path, recurse_bool do |event|
          log.info("file modified: #{event.name}, source path: #{src_path}")
          #log.info("xx syncing #{data}")
          #channel.send("from spawn #{src_path}")
          channel.send("sync_now")
          Fiber.yield
          # sync_now = true
          # Tasker.every(3.seconds) {
          # if sync_now == true
          # # start_sync log, channel
          # end
          # }
          # sync_now = false
          # log.info(sync_now)
        end
      rescue exception
        log.error(exception)
        abort "error starting Watch for: #{src_path}, #{exception}", 1
        next
      end
    end # spawn

    log.info("x1 #{sync_now}")
    # rsync to each remote_path on any changes

    if sync_now == true
      #Tasker.every(3.seconds) { start_sync log, channel }

      # data.each do |d|
      #  log.info("x2 #{sync_now}")
      # Schedule.every(3.seconds) do
      #   log.info("rsyncing #{d["src_path"]} to #{d["remote_path"]}")
      #   stdout = IO::Memory.new
      #   stderr = IO::Memory.new
      #   begin
      #     if d["remote_host"] == "localhost" || d["remote_host"] == "127.0.0.1"
      #       command = "rsync -#{d["rsync_opts"]} #{d["src_path"]} #{d["remote_path"]}/"
      #     else
      #       puts "rsync -e 'ssh -p#{d["port"]} -i #{d["priv_key"]}' -#{d["rsync_opts"]} #{d["src_path"]} #{d["remote_user"]}@#{d["remote_host"]}:/#{d["remote_path"]}"
      #       command = "rsync -e 'ssh -p#{d["port"]} -i #{d["priv_key"]}' -#{d["rsync_opts"]} #{d["src_path"]} #{d["remote_user"]}@#{d["remote_host"]}:/#{d["remote_path"]}"
      #     end

      #     exit_code = Process.run(command, shell: true, output: stdout, error: stderr).exit_code

      #     if exit_code != 0
      #       log.error("error syncing #{d["src_path"]} to #{d["remote_host"]}:#{d["remote_path"]}: #{stderr}")
      #     end
      #   rescue exception
      #     log.error(exception)
      #   end # begin
      # end   # data.each
      # end # if sync now

      sync_now = false # end of rsync cycle
    end                # Schedule
   # Fiber.yield
  end # # def
end   # # module

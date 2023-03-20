require "logger"
require "log"
require "inotify"
require "schedule"

module Poni::Watcher
  extend self
  Log = ::Log.for("Poni::Watcher")

  def spawn_watcher(src_path, data, channel)

    # channel = Channel(String).new
    Log.info {"watching #{src_path}"}

    recurse_bool = false
    # if multiple remote_paths for same source_path, a single recurse=true means all recurse=true
    data.each do |remote|
      if remote["recurse"] == "true" || remote["recurse"] == true
        recurse_bool = true
      end
    end

    # # rsync flag, if true will fire off an rsync
    sync_now = false

    spawn do
      begin
        Inotify.watch src_path, recurse_bool do |event|
          Log.info {"file modified: #{event.name}, source path: #{src_path}"}
          sync_now = true
          channel.send(src_path)
          # Fiber.yield
        end # # event
      rescue exception
        Log.error {exception}
        next
      end
    end # # spawn

    # msg = channel.receive
    # log.debug(msg)
    # log.info("1syncnow #{sync_now}")

    # data.each do |d|
    #   log.info("2syncnow #{sync_now}")

    #   # # check for any changes to src_path every interval seconds, rsync if changed
    #   Schedule.every(3.seconds) do
    #     puts "running scheduler for #{d["src_path"]}"
    #     if sync_now
    #       log.info("rsyncing #{d["src_path"]} to #{d["remote_path"]}")
    #       # stdout = IO::Memory.new
    #       # stderr = IO::Memory.new
    #       # begin
    #       # if remote_host == "localhost" || remote_host == "127.0.0.1"
    #       #     command = "rsync -#{rsync_opts} #{src_path} #{remote_path}/"
    #       # else
    #       #     puts "rsync -e 'ssh -p#{port} -i #{priv_key}' -#{rsync_opts} #{src_path} #{remote_user}@#{remote_host}:/#{remote_path}"
    #       #     command = "rsync -e 'ssh -p#{port} -i #{priv_key}' -#{rsync_opts} #{src_path} #{remote_user}@#{remote_host}:/#{remote_path}"
    #       # end

    #       # exit_code = Process.run(command, shell: true, output: stdout, error: stderr).exit_code

    #       # if exit_code != 0
    #       #     log.error("error syncing #{src_path} to #{remote_host}:#{remote_path}: #{stderr}")
    #       # end
    #       # rescue exception
    #       # log.error(exception)
    #       # end # # begin
    #     end # if

    #     # # end of rsync cycle
    #     sync_now = false
    #   end # Schedule
    # end   # data.each
    Fiber.yield
  end # def
end   # module

require "log"
require "schedule"
require "./poni"

# Scheduler starts running on startup, creates Scheduler runners that start rsync to remote whenever sync_now flag changes to True
# Signal to rsync comes from Poni main module, via Channel
# If Watcher fiber detects a modification, it alerts Poni main (via channel), which alters the sync_now flag to True

module Poni::Scheduler
  extend self
  Log = ::Log.for("Poni::Sched")

  def start_sched(src_path, sync_data, sync_now)
    interval = DEFAULTS["interval"] # default
    Log.warn { src_path }
    Log.warn { sync_data }
    Log.warn { sync_now }

    # get overal interval for single src_path spanning multiple remote paths
    interval = sync_data[0]["interval"].to_i
    # sync_data.each do |d|
    #   interval = d["interval"].to_i
    #   simulate = d["simulate"].to_s
    #   delete_on_remote = d["delete_on_remote"].to_s
    # end

    Schedule.every(interval.seconds) do
      Log.warn { "FROM SCHD" }
      Log.warn { sync_now[src_path] }
      if sync_now[src_path] == true
        sync_data.each do |d|
          Log.info { "syncing #{src_path} >> #{d["remote_host"]}:#{d["remote_path"]} now." }

          # # SYNC
          stdout = IO::Memory.new
          stderr = IO::Memory.new

          begin
            if d["remote_host"] == "localhost" || d["remote_host"] == "127.0.0.1"
              command = "rsync -#{d["rsync_opts"]} #{d["src_path"]} #{d["remote_path"]}/"
            else
              # puts "rsync -e 'ssh -p#{d["port"]} -i #{d["priv_key"]}' -#{d["rsync_opts"]} #{src_path} #{d["remote_user"]}@#{d["remote_host"]}:/#{d["remote_path"]}"
              command = "rsync -e 'ssh -p#{d["port"]} -i #{d["priv_key"]}' -#{d["rsync_opts"]} #{src_path} #{d["remote_user"]}@#{d["remote_host"]}:/#{d["remote_path"]}"
            end

            exit_code = Process.run(command, shell: true, output: stdout, error: stderr).exit_code

            if exit_code != 0
              Log.error { "error syncing #{src_path} to #{d["remote_host"]}:#{d["remote_path"]}: #{stderr}" }
            end
          rescue exception
            Log.error { exception }
          end # begin

        end # data.each
      end   # sync_now

      sync_now[src_path] = false
    end # Schedule

  end # def
end   # module

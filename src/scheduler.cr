require "log"
require "schedule"
require "./poni"

# Scheduler starts running on startup, creates Scheduler runners that start rsync to remote whenever sync_now flag changes to True
# Signal to rsync comes from Poni main module, via Channel
# If Watcher fiber detects a modification, it alerts Poni main (via channel), which alters the sync_now flag to True

module Poni::Scheduler
  extend self
  Log = ::Log.for("Poni::Sched")

  def start_sched(src_path, data, sync_now)
    interval = DEFAULTS["interval"] # default

    # get overal interval for single src_path spanning multiple remote paths
    data.each do |remote|
      interval = remote["interval"].to_i
    end

    Schedule.every(interval.seconds) do
      # Log.info { "running scheduler for #{src_path} >> #{remote["remote_path"]}" }
      # Log.info { sync_now[src_path] }
      if sync_now[src_path] == true
        data.each do |remote|
          Log.info { "SYNCING #{src_path} >> >> #{remote["remote_host"]}:#{remote["remote_path"]} now..intrv #{interval}" }

          # # SYNC
          sleep 2.seconds
        end # data.each
      end   # sync_now

      sync_now[src_path] = false
    end # Schedule

  end # def
end   # module

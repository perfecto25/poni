require "logger"
require "log"
require "inotify"
require "schedule"

module Poni::Watcher
  extend self
  Log = ::Log.for("Poni::Watcher")

  def spawn_watcher(src_path, data, channel)
    Log.info { "watching #{src_path}" }

    recurse_bool = false
    # if multiple remote_paths for same source_path, a single recurse=true means all recurse=true
    data.each do |remote|
      if remote["recurse"] == "true" || remote["recurse"] == true
        recurse_bool = true
      end
    end

    # # rsync flag, if true will fire off an rsync
    #sync_now = false

    spawn do
      begin
        Inotify.watch src_path, recurse_bool do |event|
          Log.info { "#{event.name} .... #{event.type} " }
          if event.type.to_s == "MODIFY" || event.type.to_s == "CREATE"
            Log.info { "#{event.name} (#{event.type}): source path: #{src_path}" }
            #sync_now = true
            channel.send("#{event.type}, #{src_path}")
          end

          if event.type.to_s == "DELETE"
            Log.info { "#{event.name} (#{event.type}): source path: #{src_path}" }
          end
        end # event
      rescue exception
        Log.error { exception }
        next
      end
    end # spawn

    Fiber.yield
  end # def
end   # module

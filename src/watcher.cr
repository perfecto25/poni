require "inotify"
require "schedule"

module Poni::Watcher
  extend self

  def spawn_watcher(src_path, data, channel, log)
    log.info { "watching #{src_path}" }
    recurse_bool = false
    # if multiple remote_paths for same source_path, a single recurse=true means all recurse=true
    data.each do |remote|
      if remote["recurse"] == "true" || remote["recurse"] == true
        recurse_bool = true
      end
    end

    spawn do
      begin
        Inotify.watch src_path, recurse_bool do |event|
          if event.type.to_s == "MODIFY" || event.type.to_s == "CREATE"
            log.info { "#{event.name} (#{event.type}): source path: #{src_path}" }
            channel.send("#{event.type}, #{src_path}")
          end

          if event.type.to_s == "DELETE"
            log.info { "#{event.name} (#{event.type}): source path: #{src_path}" }
          end
        end # event
      rescue exception
        log.error { "#{exception}, #{src_path}" }
        abort "#{exception}, #{src_path}", 1
      end
    end # spawn

    Fiber.yield
  end # def
end   # module

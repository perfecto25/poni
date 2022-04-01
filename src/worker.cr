require "./watcher"

module Poni::Worker
  extend self
  def spawn_worker(src_path, dst_host, dst_path)
    spawn do
      begin
        Watcher.watch(src_path) do
          puts "#{src_path} modified, syncing to #{dst_host}:#{dst_path}"
          stdout = IO::Memory.new
          stderr = IO::Memory.new
          Process.run("rsync", ["-azP", src_path, "#{dst_host}:#{dst_path}"], output: stdout, error: stderr)
        end
        Fiber.yield
      rescue exception
        puts "error"
        next
      end 
    end # spawn
  end
end # module



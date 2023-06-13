require "log"

def init_log(cfg)
  Log.setup do |c|
    if cfg.has_key?("log_path")
      begin
        backend = Log::IOBackend.new(File.new(cfg["log_path"].as_s, "a+"))
      rescue exception
        abort "error creating log: #{exception}", 1
      end
    else
      backend = Log::IOBackend.new
    end

    c.bind "*", :debug, backend
  end # log setup
end

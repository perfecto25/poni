require "log"

def init_log(cfg)
  begin
    if cfg.has_key?("log")
      log_path = cfg["log"]["destination"].as_s.downcase
      level = cfg["log"]["level"].as_s.downcase

      if log_path != "stdout"
        file = File.new(log_path, "a")
        writer = IO::MultiWriter.new(file, STDOUT)

        ::Log.setup do |c|
          c.bind "*", :warn, Log::IOBackend.new(io: writer)
        end
      end

      severity_level = case level
                     when "info"
                       Log::Severity::Info
                     when "debug"
                       Log::Severity::Debug
                     when "warning"
                       Log::Severity::Warn
                     when "error"
                       Log::Severity::Error
                     else
                       Log::Severity::Info
                     end

    else
      abort "No log destination or log level defined in config file"
    end

    log = ::Log.for("Poni")
    log.level = severity_level
    log
  rescue exception
    abort exception, 1
  end
end

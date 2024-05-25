require "log"

def init_log(cfg)
  begin
    log_path = cfg.dig?("log", "destination")
    log_level = cfg.dig?("log", "level")

    if log_path.nil?
      abort "No log destination defined in config file"
    end

    if log_level.nil?
      abort "No log level defined in config file"
    end

    log_path = log_path.as_s.downcase
    log_level = log_level.as_s.downcase

    if log_path != "stdout"
      file = File.new(log_path, "a")
      writer = IO::MultiWriter.new(file, STDOUT)

      ::Log.setup do |c|
        c.bind "*", :warn, Log::IOBackend.new(io: writer)
      end
    end

    severity_level = case log_level
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


    log = ::Log.for("Poni")
    log.level = severity_level
    log
  rescue exception
    abort exception, 1
  end
end

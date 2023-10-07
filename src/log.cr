require "logger"

def init_log(cfg)
  begin
    if cfg.has_key?("log")
      log_path = cfg["log"]["destination"].as_s.downcase

      case log_path
      when "stdout"
        log = Logger.new(STDOUT)
      else
        file = File.new(log_path, "a")
        writer = IO::MultiWriter.new(file, STDOUT)
        log = Logger.new(writer)
      end

      level = cfg["log"]["level"].as_s.downcase
      case level
      when "info"
        log.level = Logger::INFO
      when "debug"
        log.level = Logger::DEBUG
      when "warning"
        log.level = Logger::WARN
      when "error"
        log.level = Logger::ERROR
      else
        log.level = Logger::INFO
      end
    else
      abort "No log destination or log level defined in config file"
    end
    log.progname = "Poni"
    return log
  rescue exception
    abort exception, 1
  end
end

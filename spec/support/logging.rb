module Specs
  class << self
    def log
      # Setup ENV variable handling with sane defaults
      @log ||= Nenv('celluloid_specs_log') do |env|
        env.create_method(:file) { |f| f || '../../log/default.log' }
        env.create_method(:sync?) { |s| s || !Nenv.ci? }

        env.create_method(:strategy) do |strategy|
          strategy || (Nenv.ci? ? 'stderr' : 'split')
        end

        env.create_method(:level) do |level|
          begin
            Integer(level)
          rescue
            env.strategy == 'stderr' ? Logger::WARN : Logger::DEBUG
          end
        end
      end
    end

    def split_logs?
      log.strategy == 'split'
    end

    def logger
      @logger ||= default_logger.tap { |logger| logger.level = log.level }
    end

    def logger=(logger)
      @logger = logger
    end

    def default_logger
      case log.strategy
      when 'stderr'
        Logger.new(STDERR)
      when 'single'
        logfile = File.open(File.expand_path(log.file, __FILE__), 'a')
        logfile.sync if log.sync?
        Logger.new(logfile)
      when 'split'
        # Use Celluloid in case there's logging in a before/after handle
        # (is that a bug in rspec-log_split?)
        Celluloid.logger
      else
        fail "Unknown logger strategy: #{strategy.inspect}. Expected 'split', 'single' or 'stderr'."
      end
    end
  end
end

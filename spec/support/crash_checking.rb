module Specs
  class FakeLogger
    MUTEX = Mutex.new
    @@allowed_logger = nil

    def self.current
      @@allowed_logger.first
    end

    def initialize(real_logger, example)
      @mutex = Mutex.new
      @real_logger = real_logger
      @crashes = Queue.new
      @details = nil
      @example = example
      MUTEX.synchronize { @@allowed_logger = [self, example] }
    end

    def crash(*args)
      check
      @mutex.synchronize do
        fail "Testing block has already ended!" if @details
        @crashes << [args, caller.dup]
      end
    end

    def debug(*args)
      check
      @real_logger.debug(*args)
    end

    def warn(*args)
      check
      @real_logger.warn(*args)
    end

    def with_backtrace(backtrace)
      check
      yield self
    end

    def crashes
      check
      @mutex.synchronize do
        return @details if @details
        @details = []
        @details << @crashes.pop until @crashes.empty?
        @crashes = nil
        @details
      end
    end

    def crashes?
      check
      !crashes.empty?
    end

    private

    def check
      unless @@allowed_logger.first == self
        fail "Incorrect logger used:"\
          " active/allowed: \n#{@@allowed_logger.inspect},\n"\
          " actual/self: \n#{[self, @example].inspect}\n"\
          " (maybe an actor from another test is still running?)"
      end
    end
  end
end

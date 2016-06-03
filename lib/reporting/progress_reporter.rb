module Reporting
  class ProgressReporter
    def initialize
      @mutex = Mutex.new
    end

    def report(task, running_total, message)
      @mutex.synchronize do
        prefix = "#{task} progress:".ljust(40, ' ')
        counts = "#{running_total} done".rjust(30, ' ')
        puts "#{prefix}#{counts} - #{message}"
      end
    end

    def message(task, message)
      @mutex.synchronize do
        prefix = "#{task} progress:".ljust(70, ' ')
        puts "#{prefix} - #{message}"
      end
    end

    def self.noop
      NoOp.new
    end

    class NoOp
      def method_missing(method_name, *args)
        %w(report message).include?(method_name.to_s) ? nil : super
      end
    end
  end
end

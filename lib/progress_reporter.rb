class ProgressReporter
  def initialize
    @mutex = Mutex.new
  end

  def report(task, expected_total, running_total, message)
    @mutex.synchronize do
      prefix = "#{task} progress:".ljust(40, ' ')
      counts = "#{running_total}/#{expected_total} (#{'%.2f' % (100 * (running_total.to_f / expected_total))}%)".rjust(30, ' ')
      puts "#{prefix}#{counts} - #{message}"
    end
  end

  def message(task, message)
    @mutex.synchronize do
      prefix = "#{task} progress:".ljust(70, ' ')
      puts "#{prefix} - #{message}"
    end
  end
end

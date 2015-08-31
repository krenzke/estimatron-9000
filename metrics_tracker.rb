class MetricsTracker
  attr_accessor :logger

  def initialize(logger)
    @logger = logger
  end

  def run
    Thread.new {
      100.times {
        puts ENV['RABBITMQ_HOST']
        puts RUBY_PLATFORM
        process = $$
        memory = `ps -o rss #{process}`.split("\n")[1].to_f / 1024.0 rescue nil
        logger.info memory
        sleep 1
      }
    }
  end
end

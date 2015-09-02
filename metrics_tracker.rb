require 'bunny'
require 'json'

class MetricsTracker
  def initialize
    # @last_cpu_time = nil
  end

  def run
    Thread.new {
      100.times {
        publish_sample
        sleep 5
      }
      rabbit_conn.stop
    }
  end

  def sample
    {
      memory: sample_memory,
      cpu: sample_cpu,
      object_count: sample_object_count,
    }
  end

  def sample_memory
    if RUBY_PLATFORM.downcase =~ /linux/
      proc_status = File.open("/proc/#{$$}/status", "r") {|f| f.read_nonblock(4096).strip }
      if proc_status =~ /RSS:\s*(\d+) kB/i
        return $1.to_f / 1024.0
      end
    elsif RUBY_PLATFORM.downcase =~ /darwin1\d+/
      process = $$
      `ps -o rss #{process}`.split("\n")[1].to_f / 1024.0 rescue nil
    end
  end

  def sample_cpu
    # now = Time.now
    # t = Process.times
    # s = nil
    # if @last_cpu_time
    #   elapsed = now - @last_cpu_time
    #   return if elapsed < 1 # Causing some kind of math underflow

    #   usertime = t.utime - @last_utime
    #   systemtime = t.stime - @last_stime

    #   # record_systemtime(systemtime) if systemtime >= 0
    #   # record_usertime(usertime) if usertime >= 0

    #   # Calculate the true utilization by taking cpu times and dividing by
    #   # elapsed time X processor_count.

    #   # record_user_util(usertime / (elapsed * @processor_count))
    #   s = (systemtime / elapsed)
    # end
    # @last_utime = t.utime
    # @last_stime = t.stime
    # @last_cpu_time = now
    # s
  end

  def sample_object_count
    ObjectSpace.count_objects[:TOTAL] rescue nil
  end

  def publish_sample
    rabbit_exchange.publish(sample.to_json, content_type: 'application/json')
  end

  def rabbit_exchange
    @rabbit_exchange ||= rabbit_channel.fanout('services_status')
  end

  def rabbit_channel
    @rabbit_channel ||= rabbit_conn.create_channel
  end

  def rabbit_conn
    return @rabbit_conn if @rabbit_conn
    @rabbit_conn = Bunny.new(host: ENV['RABBITMQ_HOST'],
                             user: ENV['RABBITMQ_USER'],
                             pass: ENV['RABBITMQ_PASS'])
    @rabbit_conn.start
  end
end

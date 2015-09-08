require 'bunny'
require 'json'
require 'system_info'

class MetricsSampler
  def initialize
    @last_cpu_time = nil
    @num_logical_processors = SystemInfo.num_logical_processors
    @total_memory = SystemInfo.ram_in_mib
  end

  def sample
    cpu = sample_cpu
    {
      memory: sample_memory,
      cpu_user: cpu[:user_time],
      cpu_system: cpu[:system_time],
      object_count: sample_object_count,
      recorded_at: Time.now,
      total_memory: @total_memory,
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
    now = Time.now
    t = Process.times
    s = {
      user_time: nil,
      system_time: nil,
    }
    if @last_cpu_time
      elapsed = now - @last_cpu_time
      return if elapsed < 1 # Causing some kind of math underflow

      usertime = t.utime - @last_utime
      systemtime = t.stime - @last_stime

      s = {
        user_time: usertime / ( elapsed * @num_logical_processors ),
        system_time: systemtime / ( elapsed * @num_logical_processors ),
      }
    end
    @last_utime = t.utime
    @last_stime = t.stime
    @last_cpu_time = now
    s
  end

  def sample_object_count
    ObjectSpace.count_objects[:TOTAL] rescue nil
  end
end

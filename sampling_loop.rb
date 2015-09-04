require './metrics_sampler'
require './rabbit_mq_producer'
require './service_discovery'
require 'json'
require 'logger'

class SamplingLoop
  include RabbitMqProducer

  def initialize
    @sampler = MetricsSampler.new
    @service_info = ServiceDiscovery.info
    @logger = Logger.new(STDOUT)
  end

  def run
    @logger.info("SAMPLING_LOOP#run")
    @exchange ||= mq_create_exchange('services_status', :fanout)
    Thread.new {
      begin
        loop {
          @logger.info("SAMPLING_LOOP#sample")
          s = @sampler.sample.merge(@service_info)
          @exchange.publish(s.to_json, content_type: 'application/json')
          sleep 5
        }
      ensure
        mq_close
      end
    }
  end
end

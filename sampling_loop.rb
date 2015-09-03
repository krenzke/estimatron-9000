require './metrics_sampler'
require './rabbit_mq_producer'
require './service_discovery'
require 'json'

class SamplingLoop
  include RabbitMqProducer

  def intialize
    @sampler = MetricsSampler.new
    @service_info = ServiceDiscovery.info
  end

  def run
    @exchange ||= mq_create_exchange('services_status', :fanout)
    Thread.new {
      1000.times {
        s = @sampler.sample.merge(@service_info)
        @exchange.publish(s.to_json, content_type: 'application/json')
        sleep 5
      }
      mq_close
    }
  end
end

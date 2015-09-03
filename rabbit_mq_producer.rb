require 'active_support/concern'

module RabbitMqProducer
  extend ActiveSupport::Concern

  def mq_create_exchange(name, type)
    @exchanges ||= {}
    return @exchanges[name] if @exchanges[name]
    @exchanges[name] = rabbit_channel.exchange(name, type: type)
  end

  def mq_close
    @rabbit_conn.close
  end

  protected

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

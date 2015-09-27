require 'service_introspection/heroku'
require 'service_introspection/aws'
require 'service_introspection/digital_ocean'

class ServiceIntrospection
  @@hosting_platform = nil

  PLATFORMS = {
    heroku:         ServiceIntrospection::Heroku,
    aws:            ServiceIntrospection::AWS,
    digital_ocean:  ServiceIntrospection::DigitalOcean,
  }

  def self.hosting_platform
    return @@hosting_platform if @@hosting_platform

    # Maybe we got lucky and someone put it in an ENV var for us
    if ENV['HOSTING_PLATFORM']
      @@hosting_platform = ENV['HOSTING_PLATFORM'].to_sym
      return @@hosting_platform
    end
    PLATFORMS.each do |k,v|
      @@hosting_platform = k if v.is_current_platform?
    end
    @@hosting_platform ||= :unknown

    @@hosting_platform
  end

  def self.platform_specific_introspector
    platform_class = PLATFORMS[hosting_platform]
    if platform_class
      platform_class.new
    else
      nil
    end
  end

end

class ServiceDiscovery
  def self.info
    {
      service: service_name,
      host: host_name,
      hosting_platform: hosting_platform,
    }
  end

  def self.service_name
    ENV['SERVICE']
  end

  def self.host_name
    case hosting_platform
    when :heroku
      ENV['DYNO']
    else
      'localhost'
    end
  end

  def self.hosting_platform
    if ENV['DYNO']
      :heroku
    else
      :local
    end
  end
end

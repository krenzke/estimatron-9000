class ServiceIntrospection
  class AWS
    META_URL = 'http://169.254.169.254/latest/meta-data/'

    def self.is_current_platform?
      url = URI(META_URL)
      http  = Net::HTTP.new(url.host, url.port)
      http.read_timeout = 0.5
      http.open_timeout = 0.5
      res = http.get(url.path)
      res.code.to_i < 300
    rescue StandardError => e
      false
    end

    def deployment_history
      { foo: 'bar' }
    end
  end
end

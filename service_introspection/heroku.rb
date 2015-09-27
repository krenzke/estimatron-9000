require 'faraday'
require 'json'

class ServiceIntrospection
  class Heroku
    API_URL_BASE = 'https://api.heroku.com'

    def self.is_current_platform?
      ENV['DYNO'] || ENV['HEROKU_API_KEY']
    end

    def deployment_history
      return @deployment_history if @deployment_history

      # get list of most recent releases
      releases = make_heroku_request("/app/#{ENV['HEROKU_APP_ID']}/releases", {}, {
        'Range' => 'version; order=desc;'
      })

      # we're only interested in deployments, so select those
      @deployment_history = releases.select{ |e| e['description'] =~ /^Deploy/ }.map do |r|
        {
          created_at: r['created_at'],
          description: r['description'],
          version: r['version'],
          slug_id: r['slug']['id'],
        }
      end

      # need to look at the slug to get the full git sha and commit message
      @deployment_history.each do |deploy|
        slug_info = make_heroku_request("/apps/estimatron-9000/slugs/#{deploy[:slug_id]}")
        deploy[:git_sha] = slug_info['commit']
        deploy[:git_comment] = slug_info['commit_description']
      end

      @deployment_history
    end

    def service_name
      ENV['SERVICE']
    end

    def host_name
      ENV['DYNO']
    end

    protected

    def heroku_api_conn
      return @heroku_api_conn if @heroku_api_conn

      @heroku_api_conn = Faraday.new(API_URL_BASE)
      @heroku_api_conn.headers = {
        'Accept' => 'application/vnd.heroku+json; version=3',
        'Authorization' => "Bearer #{ENV['HEROKU_API_KEY']}"
      }

      @heroku_api_conn
    end

    def make_heroku_request(path, params = {}, headers = {})
      resp = heroku_api_conn.get(path, params, headers)
      if resp.headers['content-encoding'] == 'gzip'
        gz = Zlib::GzipReader.new(StringIO.new(resp.body.to_s))
        JSON.parse(gz.read)
      else resp.headers['content-type'] == ''
        JSON.parse(resp.body)
      end
    end
  end
end

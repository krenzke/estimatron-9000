# bro
RACK_ENV = ENV['RACK_ENV'] || 'development'

require 'rubygems'
require 'bundler'
Bundler.require :default, RACK_ENV
$LOAD_PATH << File.dirname(__FILE__)

Dotenv.load
require 'logger'
require 'tilt/erb'
require './metrics_tracker'

class App < Sinatra::Base
  enable :static
  enable :logging
  set :logger, ::Logger.new(STDOUT)
  set :tracker, MetricsTracker.new

  configure :production do
    settings.tracker.run
  end

  configure :development do
    register Sinatra::Reloader
    also_reload './metrics_tracker'
  end

  get '/' do
    @phrase = generate_phrase
    erb :index
  end

  get '/pulse' do
    json(settings.tracker.sample.merge({dyno: ENV['DYNO']}))
  end

  protected

  def generate_phrase
    numbers = [2,4,8,12,16]
    people = ['Burton', 'Krenzke', 'Scheirman', 'Greg']
    case rand(6)
    when 0
      "Let's just call it a #{numbers.sample} for now"
    when 1
      "Whatever #{people.sample} says it is"
    when 2
      "#{numbers.sample}-ish"
    when 3
      "No way that's anything #{['more','less'].sample} than a #{numbers.sample}"
    when 4
      "Give it a #{numbers.sample}, but don't assign the ticket to me"
    when 5
      "Call it a #{numbers.sample}, but assign a #{numbers.sample} to the rest of them"
    end
  end
end

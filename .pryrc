RACK_ENV = ENV['RACK_ENV'] || 'development'

require 'rubygems'
require 'bundler'
Bundler.require :default, RACK_ENV
$LOAD_PATH << File.dirname(__FILE__)

Dotenv.load

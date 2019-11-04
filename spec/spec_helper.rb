require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../app.rb', __FILE__

module RSpecMixin
  def app() App end
end

RSpec.configure do |c|
  c.include RSpecMixin
  c.include Rack::Test::Methods
end

require 'bundler'
Bundler.require(:default, :development)

require 'rack'
require 'rack/test'

RSpec.configure do |config|
  include Rack::Test::Methods
end

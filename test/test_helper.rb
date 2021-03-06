# -*- encoding: utf-8 -*-
$:.unshift File.dirname(__FILE__)

require 'mocha' # REVIEW: Had to place this before MiniTest - if placed after ~100 failing specs. :S
require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/spec'
require 'minitest/pride'

require 'klarna'

Dir[File.join(File.dirname(__FILE__), *%w[support ** *.rb]).to_s].each { |f| require f }

Minitest::Test.class_eval do
  include Klarna::AssertionsHelper
end

# For now Travis CI don't support multiple ENV-variables per testrun, so need this.
KLARNA_ESTORE_ID, KLARNA_ESTORE_SECRET = ENV['KLARNA_ESTORE'].to_s.split(',')

VALID_STORE_ID      = ENV['KLARNA_ESTORE_ID'].presence || KLARNA_ESTORE_ID
VALID_STORE_SECRET  = ENV['KLARNA_ESTORE_SECRET'].presence || KLARNA_ESTORE_SECRET
VALID_COUNTRY       = :SE

#Klarna.store_config_file = File.join(File.dirname(__FILE__), 'fixtures', 'klarna.yml')

FIXTURES_FILES = {
  :persons => File.join(File.dirname(__FILE__), 'fixtures', 'api', 'persons.yml'),
  :companies => File.join(File.dirname(__FILE__), 'fixtures', 'api', 'companies.yml'),
  :stores => File.join(File.dirname(__FILE__), 'fixtures', 'api', 'stores.yml')
}

@@fixtures = {}
FIXTURES_FILES.each do |fixture_key, fixture_file_path|
  @@fixtures[fixture_key] = File.open(fixture_file_path) { |file| YAML.load(file).with_indifferent_access }
end
@@fixtures = @@fixtures.with_indifferent_access

def fixture(model)
  @@fixtures[model]
end

def valid_credentials!
  Klarna.setup do |c|
    c.store_id = VALID_STORE_ID.to_i
    c.store_secret = VALID_STORE_SECRET
    c.country = VALID_COUNTRY
    c.mode = ENV['KLARNA_MODE'].presence || :test
    c.http_logging = (ENV['KLARNA_DEBUG'].to_s =~ /(true|1)/) || false
  end
end

def digest(*args)
  Klarna::API::Client.digest(*args)
end

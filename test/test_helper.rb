$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "toqua"

require "minitest/autorun"

require "rails"
require "sqlite3"
require "active_record"
require 'action_controller'
require "action_controller/railtie"
require "rails/test_help"

require 'order_query'

module TestApp
  class Application < ::Rails::Application
    config.active_support.test_order = :random
    config.secret_key_base = "abc123"
    config.eager_load = false
  end
end

TestApp::Application.initialize!

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Schema.define do
  create_table :designs do |t|
    t.integer :score
  end
end

class Design < ActiveRecord::Base
  include OrderQuery
  order_query :score_ordered, [:score, :desc]
end

class BaseTest < ActionDispatch::IntegrationTest
  def teardown
    super
    TestApp::Application.routes_reloader.reload!
    Design.delete_all
  end
end
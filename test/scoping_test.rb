require 'test_helper'

class ScopingBaseController < ActionController::Base
  include Toqua::Scoping

  scope { |s| s.merge(first: 'first') }
  scope { |s| s.merge(first: s[:first] + '_ops') }

  scope(only: :custom) { |s| s.merge(from_custom: 'Hi') }
  scope(only: [:custom, :custom_2]) { |s| s.merge(test_only_multiple: 'Hi') }

  scope(if: :param_if_as_symbol) { |s| s.merge(param_if_as_symbol: 'Hi') }
  scope(if: -> { params.key?(:if_as_lambda_test) }) { |s| s.merge(param_if_as_lambda: 'Hi') }

  scope(unless: :param_unless_as_symbol) { |s| s.merge(param_unless_as_symbol: 'Hi') }
  scope(unless: -> { params.key?(:unless_as_lambda_test) }) { |s| s.merge(param_unless_as_lambda: 'Hi') }

  def index
    render json: apply_scopes(Hash.new { Hash.new })
  end

  def custom
    render json: apply_scopes(Hash.new { Hash.new })
  end

  def custom_2
    render json: apply_scopes(Hash.new { Hash.new })
  end

  private

  def param_if_as_symbol
    params.key?(:if_as_symbol_test)
  end

  def param_unless_as_symbol
    params.key?(:unless_as_symbol_test)
  end
end

class ScopingTest < BaseTest
  def setup
    TestApp::Application.routes.draw do
      get 'index' => 'scoping_base#index'
      get 'custom' => 'scoping_base#custom'
      get 'custom_2' => 'scoping_base#custom_2'
    end
  end

  def json_response
    JSON.parse(response.body)
  end

  test 'chains in order' do
    get '/index'
    assert_equal 'first_ops', json_response["first"]
  end

  test "only restricts scope by action name" do
    get "/index"
    assert_nil json_response["from_custom"]

    get "/custom"
    assert_equal 'Hi', json_response["from_custom"]
  end

  test 'only accepts an array of actions' do
    get "/index"
    assert_nil json_response["test_only_multiple"]

    get "/custom"
    assert_equal 'Hi', json_response["test_only_multiple"]

    get "/custom_2"
    assert_equal 'Hi', json_response["test_only_multiple"]
  end

  test "#if restricts scope by conditional with symbol" do
    get "/index"
    assert_nil json_response["param_if_as_symbol"]

    get "/index?if_as_symbol_test=true"
    assert_equal 'Hi', json_response["param_if_as_symbol"]
  end

  test '#if restricts scope by conditional with lambda' do
    get "/index"
    assert_nil json_response["param_if_as_lambda"]

    get "/index?if_as_lambda_test=true"
    assert_equal 'Hi', json_response["param_if_as_lambda"]
  end

  test "#unless restricts scope by conditional with symbol" do
    get "/index"
    assert_equal "Hi", json_response["param_unless_as_symbol"]

    get "/index?unless_as_symbol_test=true"
    assert_nil json_response["param_unless_as_symbol"]
  end

  test '#unless restricts scope by conditional with lambda' do
    get "/index"
    assert_equal "Hi", json_response["param_unless_as_lambda"]

    get "/index?unless_as_lambda_test=true"
    assert_nil json_response["param_unless_as_lambda"]
  end
end

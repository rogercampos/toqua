require 'test_helper'

class KeysetBaseController < ActionController::Base
  include Toqua::KeysetPagination
  keyset_paginate :score_ordered, per: 3, headers: true

  def index
    render json: apply_scopes(Design.all)
  end
end

class KeysetPaginationTest < BaseTest
  def setup
    TestApp::Application.routes.draw do
      get 'index' => 'keyset_base#index'
    end
  end

  def json_response
    JSON.parse(response.body)
  end

  def uniq_rand_score
    x = (rand * 100).to_i

    if Design.find_by(score: x)
      uniq_rand_score
    else
      x
    end
  end

  test "pagination behavior first page" do
    10.times { Design.create!(score: uniq_rand_score) }

    expected_order = Design.order("score DESC").pluck :score

    get "/index"

    assert_equal 3, json_response.length
    assert_equal expected_order[0..2], json_response.map { |x| x["score"] }
  end

  test "pagination behavior first page with index" do
    10.times { Design.create!(score: uniq_rand_score) }

    expected_order = Design.order("score DESC").pluck :score

    get "/index?idx=#{Design.order("score DESC").first.id}"

    assert_equal 3, json_response.length
    assert_equal expected_order[0..2], json_response.map { |x| x["score"] }
  end

  test "pagination behavior second page" do
    10.times { Design.create!(score: uniq_rand_score) }

    expected_order = Design.order("score DESC").pluck(:score, :id).map { |x| { score: x[0], id: x[1] } }

    get "/index?idx=#{expected_order[3][:id]}"
    assert_equal 3, json_response.length
    assert_equal expected_order[3..5].map { |x| x[:score] }, json_response.map { |x| x["score"] }
  end

  test "headers indexes next/prev indexes on second page" do
    10.times { Design.create!(score: uniq_rand_score) }

    expected_order = Design.order("score DESC").pluck(:score, :id).map { |x| { score: x[0], id: x[1] } }

    get "/index?idx=#{expected_order[3][:id]}"

    assert_equal expected_order[3][:id], response.headers["X-KeysetPagination-Index"]
    assert_equal expected_order[6][:id], response.headers["X-KeysetPagination-Next-Index"]
    assert_equal(-1, response.headers["X-KeysetPagination-Prev-Index"]) # -1 marks previous is first page and shouldn't include index parameter
  end

  test "headers indexes next/prev indexes on first page" do
    10.times { Design.create!(score: uniq_rand_score) }

    expected_order = Design.order("score DESC").pluck(:score, :id).map { |x| { score: x[0], id: x[1] } }

    get "/index"

    assert_equal expected_order[0][:id], response.headers["X-KeysetPagination-Index"]
    assert_equal expected_order[3][:id], response.headers["X-KeysetPagination-Next-Index"]
    assert_nil response.headers["X-KeysetPagination-Prev-Index"]
  end
  test "headers indexes next/prev at 4th position" do

    10.times { Design.create!(score: uniq_rand_score) }

    expected_order = Design.order("score DESC").pluck(:score, :id).map { |x| { score: x[0], id: x[1] } }

    get "/index?idx=#{expected_order[4][:id]}"

    assert_equal expected_order[4][:id], response.headers["X-KeysetPagination-Index"]
    assert_equal expected_order[7][:id], response.headers["X-KeysetPagination-Next-Index"]
    assert_equal expected_order[1][:id], response.headers["X-KeysetPagination-Prev-Index"]
  end

  test "headers indexes next/prev passed the last page" do
    10.times { Design.create!(score: uniq_rand_score) }

    expected_order = Design.order("score DESC").pluck(:score, :id).map { |x| { score: x[0], id: x[1] } }

    get "/index?idx=#{expected_order[8][:id]}"

    res = JSON.parse response.body

    assert_equal 2, res.length
    assert_equal expected_order[8..9].map { |x| x[:score] }, res.map { |x| x["score"] }

    assert_equal expected_order[8][:id], response.headers["X-KeysetPagination-Index"]
    assert_nil response.headers["X-KeysetPagination-Next-Index"]
    assert_equal expected_order[5][:id], response.headers["X-KeysetPagination-Prev-Index"]
  end
end
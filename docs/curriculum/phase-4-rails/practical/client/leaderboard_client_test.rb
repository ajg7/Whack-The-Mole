# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require 'net/http'
require_relative 'leaderboard_client'

class LeaderboardClientTest < Minitest::Test
  Response = Struct.new(:code, :body)
  Round = Data.define(:hits, :misses) do
    def total = hits - misses
  end

  class FakeTransport
    attr_reader :requests

    def initialize(response: Response.new('201', '{}'), error: nil, delay: 0)
      @response = response
      @error = error
      @delay = delay
      @requests = []
    end

    def post(uri, body, headers)
      @requests << [uri.to_s, body, headers]
      reply
    end

    def get_response(uri)
      @requests << [uri.to_s]
      reply
    end

    private

    def reply
      sleep @delay
      raise @error if @error

      @response
    end
  end

  def client(**transport_options)
    @transport = FakeTransport.new(**transport_options)
    LeaderboardClient.new(base_url: 'http://lb.test', transport: @transport)
  end

  def test_submit_posts_the_score_as_json
    result = client.submit('AJ', Round.new(hits: 3, misses: 1))
    url, body, headers = @transport.requests.first

    assert_equal :ok, result
    assert_equal 'http://lb.test/scores', url
    assert_equal({ 'score' => { 'player_name' => 'AJ', 'points' => 2, 'hits' => 3, 'misses' => 1 } }, JSON.parse(body))
    assert_equal 'application/json', headers['Content-Type']
  end

  def test_submit_reports_a_rejected_score
    assert_equal :rejected, client(response: Response.new('422', '{}')).submit('AJ', Round.new(hits: 1, misses: 0))
  end

  def test_submit_reports_offline_for_network_errors
    [Errno::ECONNREFUSED, SocketError, Net::OpenTimeout, Net::ReadTimeout].each do |error|
      assert_equal :offline, client(error:).submit('AJ', Round.new(hits: 1, misses: 0)), error.name
    end
  end

  def test_submit_does_not_hide_bugs
    assert_raises(NoMethodError) { client(error: NoMethodError).submit('AJ', Round.new(hits: 1, misses: 0)) }
  end

  def test_top_reads_the_json_list
    body = JSON.generate([{ player_name: 'Ace', points: 20 }])
    top = client(response: Response.new('200', body)).top

    assert_equal [{ 'player_name' => 'Ace', 'points' => 20 }], top
    assert_equal ['http://lb.test/scores.json'], @transport.requests.first
  end

  def test_top_is_empty_when_anything_goes_wrong
    assert_empty client(response: Response.new('500', '[]')).top
    assert_empty client(response: Response.new('200', 'not json')).top
    assert_empty client(response: Response.new('200', '{"a":1}')).top
    assert_empty client(error: Errno::ECONNREFUSED).top
  end

  def test_submit_async_returns_at_once_and_delivers_the_result
    results = Thread::Queue.new
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    thread = client(delay: 0.5).submit_async('AJ', Round.new(hits: 1, misses: 0), results)

    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 0.2
    thread.join

    assert_equal :ok, results.pop
  end
end

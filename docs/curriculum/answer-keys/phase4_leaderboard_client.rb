# frozen_string_literal: true

require 'json'
require 'net/http'

class LeaderboardClient
  NETWORK_ERRORS = [SystemCallError, SocketError, Timeout::Error].freeze

  def initialize(base_url:, transport: Net::HTTP)
    @base_url = base_url
    @transport = transport
  end

  def submit(player_name, score)
    body = { score: { player_name:, points: score.total, hits: score.hits, misses: score.misses } }
    response = @transport.post(URI("#{@base_url}/scores"), JSON.generate(body), 'Content-Type' => 'application/json')
    response.code == '201' ? :ok : :rejected
  rescue *NETWORK_ERRORS
    :offline
  end

  def submit_async(player_name, score, results)
    Thread.new { results << submit(player_name, score) }
  end

  def top
    response = @transport.get_response(URI("#{@base_url}/scores.json"))
    return [] unless response.code == '200'

    scores = JSON.parse(response.body)
    scores.is_a?(Array) ? scores : []
  rescue JSON::ParserError, *NETWORK_ERRORS
    []
  end
end

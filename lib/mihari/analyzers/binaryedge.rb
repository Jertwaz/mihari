# frozen_string_literal: true

require "binaryedge"

module Mihari
  module Analyzers
    class BinaryEdge < Base
      attr_reader :title
      attr_reader :description
      attr_reader :query
      attr_reader :tags

      def initialize(query, title: nil, description: nil, tags: [])
        super()

        @query = query
        @title = title || "BinaryEdge lookup"
        @description = description || "query = #{query}"
        @tags = tags
      end

      def artifacts
        results = search
        return [] unless results || results.empty?

        results.map do |result|
          events = result.dig("events") || []
          events.map do |event|
            event.dig "target", "ip"
          end.compact
        end.flatten.compact.uniq
      end

      private

      PAGE_SIZE = 20

      def search_with_page(query, page: 1)
        api.host.search(query, page: page)
      end

      def search
        responses = []
        (1..Float::INFINITY).each do |page|
          res = search_with_page(query, page: page)
          total = res.dig("total").to_i

          responses << res
          break if total <= page * PAGE_SIZE
        end
        responses
      end

      def config_keys
        %w(binaryedge_api_key)
      end

      def api
        @api ||= ::BinaryEdge::API.new(Mihari.config.binaryedge_api_key)
      end
    end
  end
end

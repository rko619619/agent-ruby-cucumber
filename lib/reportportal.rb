# frozen_string_literal: true

require 'base64'
require 'cgi'
require 'http'
require 'json'
require 'mime/types'
require 'pathname'
require 'tempfile'
require 'uri'

require_relative 'report_portal/models/test_item'
require_relative 'report_portal/settings'
require_relative 'report_portal/http_client'
require_relative 'report_portal/custom_logger'

module ReportPortal
  LOG_LEVELS = { error: 'ERROR', warn: 'WARN', info: 'INFO', debug: 'DEBUG', trace: 'TRACE', fatal: 'FATAL', unknown: 'UNKNOWN' }.freeze

  class << self
    attr_accessor :launch_id, :current_scenario, :start_time, :name, :type, :description, :tags

    def initialize
      @logger = Cucumber::CustomLogger.new
    end

    def now
      (Time.now.to_f * 1000).to_i
    end

    def status_to_level(status)
      return status if LOG_LEVELS.value?(status)

      case status
      when :passed
        LOG_LEVELS[:info]
      when :failed, :undefined, :pending, :error
        LOG_LEVELS[:error]
      when :skipped
        LOG_LEVELS[:warn]
      else
        LOG_LEVELS.fetch(status, LOG_LEVELS[:info])
      end
    end

    def start_launch(description: '123', start_time: now)
      required_data = { name: Settings.instance.launch, start_time:, description: }
      data = prepare_options(required_data, Settings.instance)
      @launch_id = send_request(:post, 'launch', json: data)['id']
    end

    def finish_launch(end_time: now)
      data = { end_time: }
      @finished_launch = send_request(:put, "launch/#{@launch_id}/finish", json: data)
      @launch_link = @finished_launch['link']
      return unless Settings.instance.logLaunchLink

      @logger.info("Launch ID ReportPortal: #{@launch_link}")
    end

    def start_step(step_node:)
      item = step_node.content

      path = 'item'
      if step_node.parent && !step_node.parent.is_root?
        parent_item = step_node.parent.content

        path += "/#{parent_item.id}"
      end

      data = {
        start_time: item.start_time,
        name: item.name[0, 255],
        type: item.type.to_s,
        launch_id: @launch_id,
        description: item.description
      }

      data[:tags] = item.tags unless item.tags.empty?

      response = send_request(:post, path, json: data)

      item.id = response['id']
      item.start_time = item.start_time
    end

    def step_finished(step_node:)
      item = step_node.content
      return if item.closed

      data = {
        end_time: now,
        status: item.status
      }

      send_request(:put, "item/#{item.id}", json: data)
      item.closed = true
    end

    def start_test_case(test_case_node:)
      @current_test_case = test_case_node.content

      path = 'item'

      if test_case_node.parent && !test_case_node.parent.is_root?
        parent_item = test_case_node.parent.content
        path += "/#{parent_item.id}"
      end

      data = {
        start_time: @current_test_case.start_time,
        name: @current_test_case.name[0, 255],
        type: @current_test_case.type.to_s,
        launch_id: @launch_id,
        description: @current_test_case.description
      }

      data[:tags] = @current_test_case.tags unless @current_test_case.tags.empty?

      response = send_request(:post, path, json: data)
      @current_test_case.id = response['id']
    end

    def test_case_finished(test_case_node:)
      item = test_case_node.content

      return if item.closed

      data = {
        end_time: now,
        status: test_case_node.content.status
      }
      send_request(:put, "item/#{item.id}", json: data)
      item.closed = true
    end

    def start_suite(item_node)
      item = item_node.content

      path = 'item'
      if item_node.parent && !item_node.parent.is_root?
        parent_item = item_node.parent.content
        path += "/#{parent_item.id}"
      end

      data = {
        start_time: item.start_time,
        name: item.name[0, 255],
        type: item.type.to_s,
        launch_id: @launch_id,
        description: item.description
      }

      data[:tags] = item.tags unless item.tags.empty?
      response = send_request(:post, path, json: data)
      response['id']
    end

    def finish_suite(item_node, _status = nil, end_time = nil, _force_issue = nil)
      return if item_node.nil? || item_node.content.id.nil? || item_node.content.closed

      data = { end_time: end_time || now }
      data[:status] = 'passed'

      send_request(:put, "item/#{item_node.content.id}", json: data)

      item_node.content.closed = true
    end

    def send_log(status, message, time = now)
      return if @current_test_case.nil? || @current_test_case.closed

      data = { item_id: @current_test_case.id, time:, level: status_to_level(status), message: message.to_s }
      send_request(:post, 'log', json: data)
    end

    def send_file(status, path_or_src, label: nil, time: now, mime_type: 'image/png')
      str_without_nils = path_or_src.to_s.gsub("\0", '') # file? does not allow NULLs inside the string
      if File.file?(str_without_nils)
        send_file_from_path(status, path_or_src, label, time, mime_type)
      else
        if mime_type =~ /;base64$/
          mime_type = mime_type[0..-8]
          path_or_src = Base64.decode64(path_or_src)
        end
        extension = ".#{MIME::Types[mime_type].first.extensions.first}"
        Tempfile.open(['report_portal', extension]) do |tempfile|
          tempfile.binmode
          tempfile.write(path_or_src)
          tempfile.rewind
          send_file_from_path(status, tempfile.path, label, time, mime_type)
        end
      end
    end

    private

    def send_file_from_path(status, path, label, time, mime_type)
      File.open(File.realpath(path), 'rb') do |file|
        filename = File.basename(file)
        json = [{ level: status_to_level(status), message: label || filename, item_id: @current_test_case.id, time:, file: { name: filename } }]
        form = {
          json_request_part: HTTP::FormData::Part.new(JSON.dump(json), content_type: 'application/json'),
          binary_part: HTTP::FormData::File.new(file, filename:, content_type: MIME::Types[mime_type].first.to_s)
        }
        send_request(:post, 'log', form:)
      end
    end

    def send_request(verb, path, options = {})
      http_client.send_request(verb, path, options)
    end

    def http_client
      @http_client ||= HttpClient.new
    end

    def prepare_options(data, config = {})
      data[:attributes] = config.attributes if config.attributes
      data
    end
  end
end

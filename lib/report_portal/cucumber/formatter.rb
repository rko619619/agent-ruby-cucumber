# frozen_string_literal: true

require_relative '../../cucumber_helper'
require_relative '../settings'
require_relative '../custom_logger'
require_relative 'pretty_formatter'
require_relative 'progress_formatter'

module ReportPortal
  module Cucumber
    # Report Portal formatter service
    class Formatter
      CUCUMBER_SUPPORTED_FORMATTERS = {
        pretty: PrettyFormatter,
        progress: ProgressFormatter
      }.freeze

      def initialize(config)
        @logger = ReportPortal::CustomLogger.new
        puts 'Test'
        @formatter_service = formatter_class.new(config)
      end

      private

      def formatter_class
        CUCUMBER_SUPPORTED_FORMATTERS[cucumber_formatter_mode] || default_formatter
      end

      def cucumber_formatter_mode
        mode = ReportPortal::Settings.instance.cucumber_formatter.to_sym
        validate_cucumber_formatter_mode(mode)
      end

      def validate_cucumber_formatter_mode(mode)
        if CUCUMBER_SUPPORTED_FORMATTERS.key?(mode)
          mode
        else
          log_unsupported_mode(mode)
          :pretty
        end
      end

      def default_formatter
        CUCUMBER_SUPPORTED_FORMATTERS[:pretty]
      end

      def log_unsupported_mode(mode)
        supported_modes = CUCUMBER_SUPPORTED_FORMATTERS.keys.join(', ')
        @logger.info("Unsupported cucumber formatter mode: #{mode}.\nSupported modes: [#{supported_modes}].\nUsing default cucumber formatter - pretty.")
      end
    end
  end
end

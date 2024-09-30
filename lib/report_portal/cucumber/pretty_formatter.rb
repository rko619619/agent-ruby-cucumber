# frozen_string_literal: true

require 'cucumber/formatter/pretty'
require_relative '../../cucumber_helper'

module ReportPortal
  module Cucumber
    # Report Portal formatter with Pretty for Cucumber
    class PrettyFormatter < ::Cucumber::Formatter::Pretty
      def initialize(config)
        super(config)
        @cucumber_helper = CucumberHelper.new
        puts 'Pretty'
      end

      def bind_events(config)
        super(config)
        config.on_event :test_run_started, &method(:handle_test_run_started)
      end

      def on_test_run_finished(event)
        super(event)
        finalize_launch
      end

      def on_test_case_started(event)
        super(event)
        handle_test_case_started(event)
      end

      def on_test_case_finished(event)
        super(event)
        handle_test_case_finished(event)
      end

      def on_test_step_finished(event)
        super(event)
        handle_test_step_finished(event)
      end

      private

      def handle_test_run_started(_event)
        @cucumber_helper.start_launch
      end

      def finalize_launch
        @cucumber_helper.finish_suite
        @cucumber_helper.finish_launch
      end

      def handle_test_case_started(event)
        @cucumber_helper.feature_suite_started(feature: gherkin_document.feature)
        @cucumber_helper.test_case_started(test_case: event.test_case)
      end

      def handle_test_case_finished(event)
        @cucumber_helper.test_case_finished(test_case_result: event.result)
      end

      def handle_test_step_finished(event)
        @cucumber_helper.test_step_finished(test_step: event.test_step, test_step_result: event.result)
      end
    end
  end
end

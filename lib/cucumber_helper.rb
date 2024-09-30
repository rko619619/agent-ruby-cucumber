# frozen_string_literal: true

require 'securerandom'
require 'tree'
require_relative 'reportportal'

module ReportPortal
  module Cucumber
    # Cucumber helper for Report Portal
    class CucumberHelper
      MAX_DESCRIPTION_LENGTH = 255
      MIN_DESCRIPTION_LENGTH = 3

      def initialize
        @root_node = Tree::TreeNode.new(SecureRandom.hex, 'Launch')
        @parent_item_node = @root_node
      end

      def start_launch
        ReportPortal.start_launch
      end

      def finish_suite
        ReportPortal.finish_suite(@parent_item_node)
      end

      def finish_launch
        ReportPortal.finish_launch
      end

      def test_case_started(test_case:)
        return unless valid_description?(test_case.name)

        test_case_item = create_item(item: test_case, type: :TEST)
        test_case_node = create_tree_node(test_case_item)

        @parent_item_node << test_case_node
        @child_item_node = test_case_node
        test_case_node.content.id = ReportPortal.start_test_case(test_case_node:)
      end

      def test_case_finished(test_case_result:)
        return unless @child_item_node

        @child_item_node.content.status = test_case_result.to_sym
        ReportPortal.test_case_finished(test_case_node: @child_item_node)
        @parent_item_node.remove!(@child_item_node)
        @child_item_node = nil
      end

      def test_step_finished(test_step:, test_step_result:)
        return if test_step.hook?

        message = construct_step_message(test_step, test_step_result)
        ReportPortal.send_log(test_step_result.to_sym, message)
      end

      def feature_suite_started(feature:)
        return unless valid_description?(feature.name)

        existing_suite_node = find_existing_suite_node(feature.name)

        if existing_suite_node
          @parent_item_node = existing_suite_node
        else
          finish_parent_suite unless @parent_item_node.parent.nil?
          create_new_suite(feature)
        end
      end

      private

      def valid_description?(description)
        description.size >= MIN_DESCRIPTION_LENGTH
      end

      def create_test_case_item(test_case)
        ReportPortal::TestItem.new(
          name: truncate_description(test_case.name),
          type: :TEST,
          start_time: ReportPortal.now,
          description: test_case.name,
          tags: test_case.tags.map(&:name)
        )
      end

      def create_tree_node(item)
        Tree::TreeNode.new(SecureRandom.hex, item)
      end

      def truncate_description(description)
        description[0..MAX_DESCRIPTION_LENGTH - 1]
      end

      def construct_step_message(test_step, test_step_result)
        message = test_step.text
        return message if %i[passed warn info debug trace skipped].include?(test_step_result.to_sym)

        "#{message} - \nException: #{test_step_result.exception}"
      end

      def find_existing_suite_node(feature_name)
        @root_node.breadth_each.find do |node|
          node.content.is_a?(ReportPortal::TestItem) && node.content.name == feature_name
        end
      end

      def finish_parent_suite
        ReportPortal.finish_suite(@parent_item_node)
      end

      def create_new_suite(feature)
        suite_item = create_item(item: feature, type: :SUITE)
        suite_node = create_tree_node(suite_item)

        @root_node << suite_node
        @parent_item_node = suite_node
        suite_node.content.id = ReportPortal.start_suite(suite_node)
      end

      def create_item(item:, type:)
        ReportPortal::TestItem.new(
          name: truncate_description(item.name),
          type:,
          start_time: ReportPortal.now,
          description: item.name,
          tags: item.tags.map(&:name)
        )
      end
    end
  end
end

# frozen_string_literal: true

module ReportPortal
  # Represents a test item
  class TestItem
    attr_accessor :id, :closed, :name, :description, :type, :tags, :status, :start_time

    # Initializes the test item with the provided options
    def initialize(options = {})
      assign_attributes(options)
    end

    private

    # Assigns attributes from the provided options hash
    def assign_attributes(options)
      options = options.transform_keys(&:to_sym)
      @id = options[:id]
      @name = options[:name]
      @type = options[:type]
      @status = options[:status]
      @start_time = options[:start_time]
      @description = options[:description]
      @closed = options[:closed]
      @tags = options[:tags]
    end
  end
end

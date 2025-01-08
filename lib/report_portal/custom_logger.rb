# frozen_string_literal: true

require 'logger'
module ReportPortal
  # CustomLogger class
  class CustomLogger < Logger
    def initialize
      super($stdout)
      @formatter = proc do |severity, datetime, _progname, msg|
        "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} - #{severity.ljust(5)}: #{msg}\n"
      end
    end
  end
end

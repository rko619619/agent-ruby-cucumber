# frozen_string_literal: true

require 'logger'

# The ReportPortal module provides functionalities for interacting with the Report Portal API
# and managing logging functionalities.
module ReportPortal
  # The LoggerPatch class is responsible for extending the functionality of the built-in Logger class.
  # It adds custom logging behavior specific to the Report Portal.
  class LoggerPatch
    # Patches the Logger class to add custom logging functionality.
    def self.patch
      Logger.class_eval do
        alias_method :original_add, :add
        alias_method :original_write, :<<

        # Adds a log entry with a specific severity level.
        def add(severity, message = nil, progname = nil, &block)
          result = original_add(severity, message, progname, &block)
          return result if severity < @level

          log_message(severity, message, progname)
          result
        end

        # Writes a message to the log.
        def <<(msg)
          result = original_write(msg)
          ReportPortal.send_log(ReportPortal::LOG_LEVELS[:unknown], msg.to_s, ReportPortal.now)
          result
        end

        private

        # Logs a message to Report Portal based on its severity.
        def log_message(severity, message, progname)
          message = resolve_message(message, progname)
          formatted_severity = format_severity(severity)
          formatted_message = format_message(formatted_severity, Time.now, progname, message.to_s)
          ReportPortal.send_log(formatted_severity, formatted_message, ReportPortal.now)
        end

        # Resolves the message to log.
        def resolve_message(message, progname)
          return yield if message.nil? && block_given?

          progname ||= @progname
          message || progname
        end
      end
    end
  end

  # Invoke the patch method to extend Logger functionality.
  LoggerPatch.patch
end

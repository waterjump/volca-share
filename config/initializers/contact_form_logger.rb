# frozen_string_literal: true

contact_form_logger = Logger.new(STDOUT)
contact_form_logger.level = Logger::INFO
contact_form_logger.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime.utc.iso8601}:\n#{msg}\n"
end

Rails.application.config.contact_form_logger = contact_form_logger


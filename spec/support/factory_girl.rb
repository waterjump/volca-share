# frozen_string_literal: true

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:each) do
    begin
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.start
      # FactoryBot.lint
    ensure
      DatabaseCleaner.clean
    end
  end
end

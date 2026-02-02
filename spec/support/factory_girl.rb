# frozen_string_literal: true

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.around(:each) do |example|
    DatabaseCleaner[:mongoid].strategy = :deletion
    DatabaseCleaner[:mongoid].cleaning { example.run }
  end
end

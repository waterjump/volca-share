RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:each) do
    begin
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.start
      # FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
  end
end

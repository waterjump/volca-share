RSpec.configure do |config|
  def perform_around
    VCR.use_cassette('oembed') do
      yield
    end
  end

  config.around(:example, type: :feature) do |example|
    perform_around(&example)
  end
end

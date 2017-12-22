RSpec.configure do |config|
  def perform_around
    VCR.use_cassette('oembed') do
      yield
    end
  end

  config.around(:example) do |example|
    perform_around(&example)
  end
end

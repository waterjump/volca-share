# frozen_string_literal: true

# Block repeated POSTs to /users.
# After 3 requests in 1 day, block all requests from that IP for 1 week.
unless Rails.env.test?
  Rack::Attack.blocklist('fail2ban users post spam') do |req|
    Rack::Attack::Fail2Ban.filter("users-post-spam-#{req.ip}", maxretry: 3, findtime: 1.day, bantime: 1.week) do
      req.path == '/users' && req.post?
    end
  end
end

# Block suspicious requests for wordpress specific paths.
# After 3 blocked requests in 10 minutes, block all requests from that IP for 1 day.
Rack::Attack.blocklist('fail2ban pentesters') do |req|
  # `filter` returns truthy value if request fails, or if it's from a previously banned IP
  # so the request is blocked
  Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.day) do
    # The count for the IP is incremented if the return value is truthy
    req.path.end_with?('.php') ||
    req.path.include?('wp-admin') ||
    req.path.include?('wp-login') ||
    req.path.include?('wp-content')
  end
end

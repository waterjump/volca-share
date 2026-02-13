# frozen_string_literal: true

# Limit contact for submissions to 2 per day per IP
Rack::Attack.throttle('req/ip', limit: 2, period: 1.day) do |req|
  req.ip if req.path == '/contacts' && req.post?
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

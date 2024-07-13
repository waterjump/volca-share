Rack::Attack.throttle('req/ip', limit: 2, period: 1.day) do |req|
    req.ip if req.path == '/contacts' && req.post?
end


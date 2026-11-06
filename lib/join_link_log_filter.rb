# A request path that carries a join code logs it as [FILTERED]. Rails filters parameters and query strings, not
# the path itself.
module JoinLinkLogFilter
  PATTERN = %r{(/join/)[^/?]+}

  def self.call(path) = path.to_s.gsub(PATTERN, '\1[FILTERED]')
end

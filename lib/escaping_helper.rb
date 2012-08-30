require "cgi"

module EscapingHelper
  def escape(string)
    CGI.escape(string)
  end
end
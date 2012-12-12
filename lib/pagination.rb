module Pagination
  # Exception raised when the page number requested is either non-numeric or
  # out of the range of the results.
  class InvalidPage < ArgumentError
  end

  # Paginate a result set according to a user-supplied page parameter. Pages
  # are 1-indexed.
  #
  # If the page parameter is a non-integer string, or if it is too low or high,
  # raise an InvalidPage exception.
  #
  # If the page parameter is nil (i.e. not in the request), default to 1.
  def paginated(scope, page_param)
    if page_param
      begin
        page_number = Integer(page_param)
      rescue ArgumentError
        raise InvalidPage, "Invalid page number: #{page_param.inspect}"
      end
    else
      # If page parameter is nil (i.e. not supplied)
      page_number = 1
    end

    raise InvalidPage, "Page number #{page_number} < 1" if page_number < 1

    paginated_scope = scope.page(page_number)

    # Raise an exception if we've shot off the end of the results
    # (unless, of course, we're on the first page and there are no results)
    if page_number > 1 && paginated_scope.offset >= paginated_scope.count
      raise InvalidPage, "Page number #{page_number} too high"
    end

    return paginated_scope
  end

  # Wrapper class to access information from a paginated result set.
  #
  # Example use:
  #
  #   p = PaginatedResultSet.new(Tag.page(3))
  #
  #   p.current_page  # 3
  #   p.results       # [#<Tag ...>, ...]
  #
  class PaginatedResultSet

    extend Forwardable

    # Delegate, delegate method, [local alias]
    def_delegator :@scope, :total_count, :total
    def_delegator :@scope, :total_pages, :pages
    def_delegator :@scope, :limit_value, :page_size
    def_delegator :@scope, :current_page

    def initialize(scope)
      @scope = scope
    end

    def results
      @results ||= @scope.to_a
    end

    def start_index
      @scope.offset + 1
    end
  end
end

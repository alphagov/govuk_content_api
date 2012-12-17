require "link_header"

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

    attr_accessor :links

    extend Forwardable

    # Delegate, delegate method, [local alias]
    def_delegator :@scope, :total_count, :total
    def_delegator :@scope, :total_pages, :pages
    def_delegator :@scope, :limit_value, :page_size
    def_delegator :@scope, :current_page

    def_delegator :@scope, :last_page?
    def_delegator :@scope, :first_page?

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

  # Wrapper class to mimic a PaginatedResultSet for non-paginated results.
  #
  # The `scope` parameter can be any object that can be converted to an array
  # (one that responds to the `to_a` method).
  class FakePaginatedResultSet

    def initialize(scope)
      @scope = scope
    end

    def results
      @results ||= @scope.to_a
    end

    def start_index
      1
    end

    def total
      results.count
    end

    def pages
      1
    end

    def page_size
      total
    end

    def current_page
      1
    end

    def first_page?
      true
    end

    def last_page?
      true
    end
  end

  # Generate an array of LinkHeader::Link objects from a paginated set.
  #
  # The block should be a function that takes a page number and returns a URL.
  def page_links_from(result_set, &generate_link)
    links = []
    unless @result_set.last_page?
      links.push LinkHeader::Link.new(
        generate_link.call(@result_set.current_page + 1),
        [["rel", "next"]]
      )
    end
    unless @result_set.first_page?
      links.push LinkHeader::Link.new(
        generate_link.call(@result_set.current_page - 1),
        [["rel", "previous"]]
      )
    end

    links
  end
end

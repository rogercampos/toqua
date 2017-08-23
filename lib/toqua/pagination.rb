module Toqua
  module Pagination
    extend ActiveSupport::Concern
    include Scoping

    DEFAULT_PAGE = 1
    DEFAULT_PAGE_KEY = :page
    DEFAULT_PER_PAGE = 30
    DEFAULT_PER_PAGE_KEY = :per_page

    included do
      helper_method :paginated?
    end

    def paginated?
      @paginated
    end

    class_methods do
      def paginate(opts = {})
        page_key = opts.fetch(:page_key, DEFAULT_PAGE_KEY)
        per_page_key = opts.fetch(:per_page_key, DEFAULT_PER_PAGE_KEY)

        scope_opts = opts.slice(:if, :unless, :only)

        scope(scope_opts) do |scope|
          @paginated = true

          @page = params.fetch(page_key, opts.fetch(:page, DEFAULT_PAGE))
          per = params.fetch(per_page_key, opts.fetch(:per, DEFAULT_PER_PAGE))

          if opts[:headers]
            scope_count = scope.count
            headers['X-Pagination-Total'] = scope_count.is_a?(Hash) ? scope_count.keys.count.to_s : scope_count.to_s
            headers['X-Pagination-Per-Page'] = per.to_s
            headers['X-Pagination-Page'] = @page.to_s
          end

          per == '0' ? scope : scope.page(@page).per(per)
        end
      end
    end
  end
end
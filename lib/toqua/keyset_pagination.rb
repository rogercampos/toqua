module Toqua
  module KeysetPagination
    extend ActiveSupport::Concern
    include Scoping

    DEFAULT_INDEX_KEY = :idx
    DEFAULT_PER_PAGE = 30

    included do
      helper_method :paginated?
    end

    def paginated?
      @paginated
    end

    class_methods do
      def keyset_paginate(order_query_name, opts = {})
        opts.assert_valid_keys(:per, :index_key, :headers)
        per = opts.fetch(:per, DEFAULT_PER_PAGE)
        index_key = opts.fetch(:index_key, DEFAULT_INDEX_KEY)

        scope do |scope|
          idx = params[index_key].presence

          if idx
            current_object = scope.model.find_by(id: idx)
          end

          current_object ||= scope.send(order_query_name).first

          if current_object # Only in case there are no objects to paginate
            @paginated = true

            point = scope.model.send("#{order_query_name}_at", current_object)

            two_previous_points = point.before.merge(scope.except(:order, :preload, :eager_load)).offset(per - 1).limit(2).to_a

            if two_previous_points.empty?
              @keyset_pagination_prev_index = nil
            elsif two_previous_points.size == 1
              @keyset_pagination_prev_index = -1
            else
              @keyset_pagination_prev_index = two_previous_points.first.id
            end

            @keyset_pagination_next_index = point.after.merge(scope.except(:order, :preload, :eager_load)).offset(per - 1).first.try(:id)

            if opts[:headers]
              headers['X-KeysetPagination-Index'] = current_object.id
              headers['X-KeysetPagination-Next-Index'] = @keyset_pagination_next_index
              headers['X-KeysetPagination-Prev-Index'] = @keyset_pagination_prev_index
            end

            scope.except(:order).merge(point.after(false).limit(per)).send(order_query_name)
          else
            scope
          end
        end
      end
    end
  end
end

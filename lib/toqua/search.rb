require 'recursive-open-struct'

module Toqua
  module Search
    extend ActiveSupport::Concern
    include Scoping

    included do
      helper_method :search_params, :searching?, :search_object, :active_search_params
    end

    def search_params
      params[:q].permit! if params[:q]
      (params[:q] || {}).to_h.reverse_merge(default_search_params)
    end

    def active_search_params
      search_params.select { |_, b| !b.nil? && b != "" }.to_h
    end

    def search_object
      @search_object ||= begin
        Class.new(RecursiveOpenStruct) do
          extend ActiveModel::Naming

          def self.model_name
            ActiveModel::Name.new(Class, nil, "q")
          end
        end.new(search_params)
      end
    end

    def searching?
      params.key?(:q)
    end

    def default_search_params
      {}
    end

    class_methods do
      def searchable
        scope { |s| s.filter(search_params) }
      end
    end
  end
end

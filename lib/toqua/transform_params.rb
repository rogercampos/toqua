module Toqua
  module TransformParams
    extend ActiveSupport::Concern

    class ParameterConverter
      def parse(params, hash, block)
        if Hash === hash
          key = hash.keys.first

          if params.key?(key)
            parse(params[key], hash[key], block)
          end
        else
          if params.key?(hash)
            params[hash] = block.call(params[hash])
          end
        end
      end
    end

    included do
      class_attribute(:__transform_params)
      self.__transform_params = []

      prepend_before_action do
        self.class.__transform_params.each do |hash, block|
          ParameterConverter.new.parse(params, hash, block)
        end
      end
    end

    class_methods do
      def transform_params(hash, &block)
        self.__transform_params += [[hash, block]]
      end
    end
  end
end
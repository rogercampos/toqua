module Toqua
  module Scoping
    extend ActiveSupport::Concern

    def apply_scopes(start)
      s = start
      self.class.__scopes.each do |scope, opts|
        s = __run_scope(s, scope, opts)
      end
      s
    end

    def __run_scope(relation, scope, opts)
      if_condition = if opts[:if]
                       opts[:if].respond_to?(:call) ? !!instance_exec(&opts[:if]) : send(opts[:if])
                     elsif opts[:unless]
                       opts[:unless].respond_to?(:call) ? !instance_exec(&opts[:unless]) : !send(opts[:unless])
                     else
                       true
                     end

      action_condition = if opts[:only]
                           [opts[:only]].flatten.include?(action_name.to_sym)
                         else
                           true
                         end

      if if_condition && action_condition
        self.instance_exec(relation, &scope)
      else
        relation
      end
    end

    included do
      class_attribute(:__scopes)
      self.__scopes = []
    end

    class_methods do
      def scope(opts = {}, &block)
        self.__scopes += [[block, opts]]
      end
    end
  end
end
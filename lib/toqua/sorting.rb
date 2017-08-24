module Toqua
  module Sorting
    extend ActiveSupport::Concern

    class_methods do
      def sorting(opts = {})
        reorder = opts.fetch(:reorder, true)

        scope do |s|
          if params[:s].present?
            attr_name, direction = params[:s].to_s.split("+").map(&:strip)
            raise "You must provide an attribute to sort by" unless attr_name
            raise "You must provide a direction" unless direction

            direction.downcase!
            raise "Direction must be ASC or DESC" unless ["asc", "desc"].include?(direction)

            s.send(reorder ? :reorder : :order, s.arel_table[attr_name].send(direction))
          else
            s
          end
        end
      end
    end
  end
end
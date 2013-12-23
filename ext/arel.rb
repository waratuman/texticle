module Arel
  class SelectManager < Arel::TreeManager

    def distinct_on(expr)
      if expr == false
        @ctx.set_quantifier = nil
      else
        @ctx.set_quantifier = Arel::Nodes::DistinctOn.new(expr)
      end
    end

  end
end

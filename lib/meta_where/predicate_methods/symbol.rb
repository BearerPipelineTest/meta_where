module MetaWhere
  module PredicateMethods
    module Symbol
      def predicate(method_name, value = :__undefined__)
        Nodes::Predicate.new self, method_name, value
      end
    end
  end
end
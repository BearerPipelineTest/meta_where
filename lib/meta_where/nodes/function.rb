module MetaWhere
  module Nodes
    class Function

      attr_reader :name, :args, :alias

      def initialize(name, args)
        @name, @args = name, args
      end

      def as(alias_name)
        @alias = alias_name.to_s
        self
      end

      MetaWhere::PREDICATES.each do |method_name|
        eval <<-RUBY
          def #{method_name}(value = :__undefined__)
            Predicate.new self, :#{method_name}, value
          end
        RUBY
      end

      def >>(value)
        Predicate.new self, :eq, value
      end

      def ^(value)
        Predicate.new self, :not_eq, value
      end

      def +(value)
        Predicate.new self, :in, value
      end

      def -(value)
        Predicate.new self, :not_in, value
      end

      def =~(value)
        Predicate.new self, :matches, value
      end

      # Won't work on Ruby 1.8.x so need to do this conditionally
      define_method('!~') do |value|
        Predicate.new(self.symbol, value, :does_not_match)
      end if respond_to?('!~')

      def >(value)
        Predicate.new self, :gt, value
      end

      def >=(value)
        Predicate.new self, :gteq, value
      end

      def <(value)
        Predicate.new self, :lt, value
      end

      def <=(value)
        Predicate.new self, :lteq, value
      end

      # expand_hash_conditions_for_aggregates assumes our hash keys can be
      # converted to symbols, so this has to be implemented, but it doesn't
      # really have to do anything useful.
      def to_sym
        nil
      end

    end
  end
end
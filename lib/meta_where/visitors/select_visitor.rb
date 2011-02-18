require 'meta_where/visitors/base'
require 'meta_where/contexts/join_dependency_context'

module MetaWhere
  module Visitors
    class SelectVisitor < Base

      def visit_Hash(o, parent)
        o.map do |k, v|
          if implies_context_change?(v)
            visit_with_context_change(k, v, parent)
          else
            visit_without_context_change(k, v, parent)
          end
        end.flatten
      end

      def implies_context_change?(v)
        Hash === v || can_accept?(v) ||
        (Array === v && !v.empty? && v.all? {|val| can_accept?(val)})
      end

      def visit_with_context_change(k, v, parent)
        parent = case k
          when Nodes::KeyPath
            traverse(k.path_with_endpoint, parent)
          else
            find(k, parent)
          end

        if Array === v
          v.map {|val| accept(val, parent || k)}
        else
          can_accept?(v) ? accept(v, parent || k) : v
        end
      end

      def visit_without_context_change(k, v, parent)
        v
      end

      def visit_Array(o, parent)
        o.map { |v| can_accept?(v) ? accept(v, parent) : v }.flatten
      end

      def visit_Symbol(o, parent)
        contextualize(parent)[o]
      end

      def visit_MetaWhere_Nodes_Stub(o, parent)
        contextualize(parent)[o.symbol]
      end

      def visit_MetaWhere_Nodes_KeyPath(o, parent)
        parent = traverse(o.path, parent)

        accept(o.endpoint, parent)
      end

      def visit_MetaWhere_Nodes_Function(o, parent)
        args = o.args.map do |arg|
          case arg
          when Nodes::Function
            accept(arg, parent)
          when Symbol
            Arel.sql(arel_visitor.accept contextualize(parent)[arg])
          when Nodes::Stub
            Arel.sql(arel_visitor.accept contextualize(parent)[arg.symbol])
          else
            arg
          end
        end
        Arel::Nodes::NamedFunction.new(o.name, args, o.alias)
      end

    end
  end
end
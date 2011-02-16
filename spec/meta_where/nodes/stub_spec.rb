require 'spec_helper'

module MetaWhere
  module Nodes
    describe Stub do
      before do
        @s = Stub.new :attribute
      end

      it 'hashes like a symbol' do
        @s.hash.should eq :attribute.hash
      end

      it 'returns its symbol when sent to_sym' do
        @s.to_sym.should eq :attribute
      end

      it 'returns a string matching its symbol when sent to_s' do
        @s.to_s.should eq 'attribute'
      end

      MetaWhere::PREDICATES.each do |method_name|
        it "creates #{method_name} predicates with no value" do
          predicate = @s.send(method_name)
          predicate.expr.should eq :attribute
          predicate.method_name.should eq method_name
          predicate.value?.should be_false
        end

        it "creates #{method_name} predicates with a value" do
          predicate = @s.send(method_name, 'value')
          predicate.expr.should eq :attribute
          predicate.method_name.should eq method_name
          predicate.value.should eq 'value'
        end
      end

      MetaWhere::DEFAULT_PREDICATE_ALIASES.each do |method_name, aliases|
        aliases.each do |aliaz|
          ['', '_any', '_all'].each do |suffix|
            it "creates #{method_name.to_s + suffix} predicates with no value using the alias #{aliaz.to_s + suffix}" do
              predicate = @s.send(aliaz.to_s + suffix)
              predicate.expr.should eq :attribute
              predicate.method_name.should eq (method_name.to_s + suffix).to_sym
              predicate.value?.should be_false
            end

            it "creates #{method_name.to_s + suffix} predicates with a value using the alias #{aliaz.to_s + suffix}" do
              predicate = @s.send((aliaz.to_s + suffix), 'value')
              predicate.expr.should eq :attribute
              predicate.method_name.should eq (method_name.to_s + suffix).to_sym
              predicate.value.should eq 'value'
            end
          end
        end
      end

      it 'creates eq predicates with >>' do
        predicate = @s >> 1
        predicate.expr.should eq :attribute
        predicate.method_name.should eq :eq
        predicate.value.should eq 1
      end

      it 'creates not_eq predicates with ^' do
        predicate = @s ^ 1
        predicate.expr.should eq :attribute
        predicate.method_name.should eq :not_eq
        predicate.value.should eq 1
      end

      it 'creates in predicates with +' do
        predicate = @s + [1,2,3]
        predicate.expr.should eq :attribute
        predicate.method_name.should eq :in
        predicate.value.should eq [1,2,3]
      end

      it 'creates not_in predicates with -' do
        predicate = @s - [1,2,3]
        predicate.expr.should eq :attribute
        predicate.method_name.should eq :not_in
        predicate.value.should eq [1,2,3]
      end

      it 'creates matches predicates with =~' do
        predicate = @s =~ '%bob%'
        predicate.expr.should eq :attribute
        predicate.method_name.should eq :matches
        predicate.value.should eq '%bob%'
      end

      it 'creates does_not_match predicates with !~' do
        predicate = @s =~ '%bob%'
        predicate.expr.should eq :attribute
        predicate.method_name.should eq :matches
        predicate.value.should eq '%bob%'
      end

      it 'creates gt predicates with >' do
        predicate = @s > 1
        predicate.expr.should eq :attribute
        predicate.method_name.should eq :gt
        predicate.value.should eq 1
      end

      it 'creates gteq predicates with >=' do
        predicate = @s >= 1
        predicate.expr.should eq :attribute
        predicate.method_name.should eq :gteq
        predicate.value.should eq 1
      end

      it 'creates lt predicates with <' do
        predicate = @s < 1
        predicate.expr.should eq :attribute
        predicate.method_name.should eq :lt
        predicate.value.should eq 1
      end

      it 'creates lteq predicates with <=' do
        predicate = @s <= 1
        predicate.expr.should eq :attribute
        predicate.method_name.should eq :lteq
        predicate.value.should eq 1
      end

      it 'creates ascending orders' do
        order = @s.asc
        order.should be_ascending
      end

      it 'creates descending orders' do
        order = @s.desc
        order.should be_descending
      end

      it 'creates inner joins' do
        join = @s.inner
        join.should be_a Join
        join.type.should eq Arel::InnerJoin
      end

      it 'creates outer joins' do
        join = @s.outer
        join.should be_a Join
        join.type.should eq Arel::OuterJoin
      end

      it 'creates functions with #func' do
        function = @s.func
        function.should be_a Function
      end

      it 'creates functions with #[]' do
        function = @s[1, 2, 3]
        function.should be_a Function
        function.args.should eq [1, 2, 3]
      end

    end
  end
end
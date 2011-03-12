module MetaWhere
  module Nodes
    describe Operation do
      before do
        @f = dsl{name + 1}
      end

      MetaWhere::Constants::PREDICATES.each do |method_name|
        it "creates #{method_name} predicates with no value" do
          predicate = @f.send(method_name)
          predicate.expr.should eq @f
          predicate.method_name.should eq method_name
          predicate.value?.should be_false
        end

        it "creates #{method_name} predicates with a value" do
          predicate = @f.send(method_name, 'value')
          predicate.expr.should eq @f
          predicate.method_name.should eq method_name
          predicate.value.should eq 'value'
        end
      end

      MetaWhere::Constants::PREDICATE_ALIASES.each do |method_name, aliases|
        aliases.each do |aliaz|
          ['', '_any', '_all'].each do |suffix|
            it "creates #{method_name.to_s + suffix} predicates with no value using the alias #{aliaz.to_s + suffix}" do
              predicate = @f.send(aliaz.to_s + suffix)
              predicate.expr.should eq @f
              predicate.method_name.should eq "#{method_name}#{suffix}".to_sym
              predicate.value?.should be_false
            end

            it "creates #{method_name.to_s + suffix} predicates with a value using the alias #{aliaz.to_s + suffix}" do
              predicate = @f.send((aliaz.to_s + suffix), 'value')
              predicate.expr.should eq @f
              predicate.method_name.should eq "#{method_name}#{suffix}".to_sym
              predicate.value.should eq 'value'
            end
          end
        end
      end

      it 'creates eq predicates with ==' do
        predicate = @f == 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :eq
        predicate.value.should eq 1
      end

      it 'creates not_eq predicates with ^' do
        predicate = @f ^ 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :not_eq
        predicate.value.should eq 1
      end

      it 'creates not_eq predicates with !=' do
        predicate = @f != 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :not_eq
        predicate.value.should eq 1
      end if respond_to?('!=')

      it 'creates in predicates with >>' do
        predicate = @f >> [1,2,3]
        predicate.expr.should eq @f
        predicate.method_name.should eq :in
        predicate.value.should eq [1,2,3]
      end

      it 'creates not_in predicates with <<' do
        predicate = @f << [1,2,3]
        predicate.expr.should eq @f
        predicate.method_name.should eq :not_in
        predicate.value.should eq [1,2,3]
      end

      it 'creates matches predicates with =~' do
        predicate = @f =~ '%bob%'
        predicate.expr.should eq @f
        predicate.method_name.should eq :matches
        predicate.value.should eq '%bob%'
      end

      it 'creates does_not_match predicates with !~' do
        predicate = @f !~ '%bob%'
        predicate.expr.should eq @f
        predicate.method_name.should eq :does_not_match
        predicate.value.should eq '%bob%'
      end if respond_to?('!~')

      it 'creates gt predicates with >' do
        predicate = @f > 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :gt
        predicate.value.should eq 1
      end

      it 'creates gteq predicates with >=' do
        predicate = @f >= 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :gteq
        predicate.value.should eq 1
      end

      it 'creates lt predicates with <' do
        predicate = @f < 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :lt
        predicate.value.should eq 1
      end

      it 'creates lteq predicates with <=' do
        predicate = @f <= 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :lteq
        predicate.value.should eq 1
      end

      describe '#as' do

        it 'aliases the function' do
          @f.as('the_alias')
          @f.alias.should eq 'the_alias'
        end

        it 'casts the alias to a string' do
          @f.as(:the_alias)
          @f.alias.should eq 'the_alias'
        end

      end

    end
  end
end
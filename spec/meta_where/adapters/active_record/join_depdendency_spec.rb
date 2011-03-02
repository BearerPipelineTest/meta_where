module MetaWhere
  module Adapters
    module ActiveRecord
      describe JoinDependency do
        before do
          @jd = ::ActiveRecord::Associations::JoinDependency.new(Person, {}, [])
        end

        it 'joins with symbols' do
          @jd.send(:build, :articles => :comments)
          @jd.join_associations.should have(2).associations
          @jd.join_associations.each do |association|
            association.join_type.should eq Arel::InnerJoin
          end
        end

        it 'joins with stubs' do
          @jd.send(:build, Nodes::Stub.new(:articles) => Nodes::Stub.new(:comments))
          @jd.join_associations.should have(2).associations
          @jd.join_associations.each do |association|
            association.join_type.should eq Arel::InnerJoin
          end
          @jd.join_associations[0].table_name.should eq 'articles'
          @jd.join_associations[1].table_name.should eq 'comments'
        end

        it 'joins using outer joins' do
          @jd.send(:build, :articles.outer => :comments.outer)
          @jd.join_associations.should have(2).associations
          @jd.join_associations.each do |association|
            association.join_type.should eq Arel::OuterJoin
          end
        end

      end
    end
  end
end
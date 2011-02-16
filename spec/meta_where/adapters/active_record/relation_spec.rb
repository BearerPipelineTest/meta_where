module MetaWhere
  module Adapters
    module ActiveRecord
      describe Relation do

        describe '#predicate_visitor' do

          it 'creates a predicate visitor with a JoinDependencyContext for the relation' do
            relation = Person.joins({
              :children => {
                :children => {
                  :parent => :parent
                }
              }
            })

            visitor = relation.predicate_visitor

            visitor.should be_a Visitors::PredicateVisitor
            table = visitor.contextualize(relation.join_dependency.join_parts.last)
            table.table_alias.should eq 'parents_people_2'
          end

        end

        describe '#order_visitor' do

          it 'creates an order visitor with a JoinDependencyContext for the relation' do
            relation = Person.joins({
              :children => {
                :children => {
                  :parent => :parent
                }
              }
            })

            visitor = relation.order_visitor

            visitor.should be_a Visitors::OrderVisitor
            table = visitor.contextualize(relation.join_dependency.join_parts.last)
            table.table_alias.should eq 'parents_people_2'
          end

        end

        describe '#build_arel' do

          it 'joins associations' do
            relation = Person.joins({
              :children => {
                :children => {
                  :parent => :parent
                }
              }
            })

            arel = relation.build_arel

            relation.join_dependency.join_associations.should have(4).items
            arel.to_sql.should match /INNER JOIN "people" "parents_people_2" ON "parents_people_2"."id" = "parents_people"."parent_id"/
          end

          it 'joins associations with custom join types' do
            relation = Person.joins({
              :children.outer => {
                :children => {
                  :parent => :parent.outer
                }
              }
            })

            arel = relation.build_arel

            relation.join_dependency.join_associations.should have(4).items
            arel.to_sql.should match /LEFT OUTER JOIN "people" "children_people"/
            arel.to_sql.should match /LEFT OUTER JOIN "people" "parents_people_2" ON "parents_people_2"."id" = "parents_people"."parent_id"/
          end

          it 'only joins an association once, even if two overlapping joins_values hashes are given' do
            relation = Person.joins({
              :children => {
                :children => {
                  :parent => :parent
                }
              }
            }).joins({
              :children => {
                :children => {
                  :children => :parent
                }
              }
            })

            arel = relation.build_arel
            relation.join_dependency.join_associations.should have(6).items
            arel.to_sql.should match /INNER JOIN "people" "parents_people_3" ON "parents_people_3"."id" = "children_people_3"."parent_id"/
          end

          it 'visits wheres with a PredicateVisitor, converting them to ARel nodes' do
            relation = Person.where(:name.matches => '%bob%')
            arel = relation.build_arel
            arel.to_sql.should match /"people"."name" LIKE '%bob%'/
          end

          it 'maps wheres inside a hash to their appropriate association table' do
            relation = Person.joins({
              :children => {
                :children => {
                  :parent => :parent
                }
              }
            }).where({
              :children => {
                :children => {
                  :parent => {
                    :parent => { :name => 'bob' }
                  }
                }
              }
            })

            arel = relation.build_arel

            arel.to_sql.should match /"parents_people_2"."name" = 'bob'/
          end

          it 'combines multiple conditions of the same type against the same column with AND' do
            relation = Person.where(:name.matches => '%bob%')
            relation = relation.where(:name.matches => '%joe%')
            arel = relation.build_arel
            arel.to_sql.should match /"people"."name" LIKE '%bob%' AND "people"."name" LIKE '%joe%'/
          end

          it 'maps havings inside a hash to their appropriate association table' do
            relation = Person.joins({
              :children => {
                :children => {
                  :parent => :parent
                }
              }
            }).having({
              :children => {
                :children => {
                  :parent => {
                    :parent => {:name => 'joe'}
                  }
                }
              }
            })

            arel = relation.build_arel

            arel.to_sql.should match /HAVING "parents_people_2"."name" = 'joe'/
          end

          it 'maps orders inside a hash to their appropriate association table' do
            relation = Person.joins({
              :children => {
                :children => {
                  :parent => :parent
                }
              }
            }).order({
              :children => {
                :children => {
                  :parent => {
                    :parent => :id.asc
                  }
                }
              }
            })

            arel = relation.build_arel

            arel.to_sql.should match /ORDER BY "parents_people_2"."id" ASC/
          end

        end

        describe '#select' do

          it 'accepts options from a block' do
            standard = Person.select(:id)
            block = Person.select {id}
            block.to_sql.should eq standard.to_sql
          end

          it 'falls back to Array#select behavior with a block that has an arity' do
            people = Person.select {|p| p.name =~ /John/}
            people.should have(1).person
            people.first.name.should eq 'Miss Cameron Johnson'
          end

          it 'behaves as normal with standard parameters' do
            people = Person.select(:id)
            people.should have(332).people
            expect { people.first.name }.to raise_error ActiveModel::MissingAttributeError
          end

          it 'allows a function in the select values via Symbol#func' do
            relation = Person.select(:max.func(:id).as('max_id'))
            relation.first.max_id.should eq 332
          end

          it 'allows a function in the select values via block' do
            relation = Person.select{max[id].as(max_id)}
            relation.first.max_id.should eq 332
          end

        end

        describe '#where' do

          it 'builds options with a block' do
            standard = Person.where(:name => 'bob')
            block = Person.where{{name => 'bob'}}
            block.to_sql.should eq standard.to_sql
          end

          it 'builds compound conditions with a block' do
            standard = Person.where(:name => 'bob', :salary => 100000)
            block = Person.where{name >> 'bob' & salary >> 100000}
            block.to_sql.should eq standard.to_sql
          end

          it 'allows mixing hash and operator syntax inside a block' do
            standard = Person.joins(:comments).
                              where(:name => 'bob', :comments => {:body => 'First post!'})
            block = Person.joins(:comments).
                           where{name >> 'bob' & {comments => body >> 'First post!'}}
            block.to_sql.should eq standard.to_sql
          end

        end

        describe '#joins' do

          it 'builds options with a block' do
            standard = Person.joins(:children => :children)
            block = Person.joins{{children => children}}
            block.to_sql.should eq standard.to_sql
          end

          it 'accepts multiple top-level associations with a block' do
            standard = Person.joins(:children, :articles, :comments)
            block = Person.joins{[children, articles, comments]}
            block.to_sql.should eq standard.to_sql
          end

          it 'joins polymorphic belongs_to associations' do
            relation = Note.joins{notable(Article)}
            relation.to_sql.should match /"notes"."notable_type" = 'Article'/
          end

          it "only joins once, even if two join types are used" do
            relation = Person.joins(:articles.inner, :articles.outer)
            relation.to_sql.scan("JOIN").size.should eq 1
          end

        end

        describe '#having' do

          it 'builds options with a block' do
            standard = Person.having(:name => 'bob')
            block = Person.having{{name => 'bob'}}
            block.to_sql.should eq standard.to_sql
          end

          it 'allows complex conditions on aggregate columns' do
            relation = Person.group(:parent_id).having{salary >> max[salary]}
            relation.first.name.should eq 'Gladyce Kulas'
          end

        end

        describe '#order' do

          it 'builds options with a block' do
            standard = Person.order(:name)
            block = Person.order{name}
            block.to_sql.should eq standard.to_sql
          end

        end

        describe '#build_where' do

          it 'sanitizes SQL as usual with strings' do
            wheres = Person.where('name like ?', '%bob%').where_values
            wheres.should eq ["name like '%bob%'"]
          end

          it 'sanitizes SQL as usual with arrays' do
            wheres = Person.where(['name like ?', '%bob%']).where_values
            wheres.should eq ["name like '%bob%'"]
          end

          it 'adds hash where values without converting to ARel predicates' do
            wheres = Person.where({:name => 'bob'}).where_values
            wheres.should eq [{:name => 'bob'}]
          end

        end

        describe '#debug_sql' do

          it 'returns the query that would be run against the database, even if eager loading' do
            relation = Person.includes(:comments, :articles).
              where(:comments => {:body => 'First post!'}).
              where(:articles => {:title => 'Hello, world!'})
            relation.debug_sql.should_not eq relation.to_sql
            relation.debug_sql.should match /SELECT "people"."id" AS t0_r0/
          end

        end

        describe '#where_values_hash' do

          it 'allows creation of new records with equality predicates from wheres' do
            @person = Person.where(:name => 'bob', :parent_id => 3).new
            @person.parent_id.should eq 3
            @person.name.should eq 'bob'
          end

        end

        describe '#to_a' do

          it 'eager-loads associations with dependent conditions' do
            relation = Person.includes(:comments, :articles).
              where{{comments => {body => 'First post!'}}}
            relation.size.should be 1
            person = relation.first
            person.name.should eq 'Gladyce Kulas'
            person.comments.loaded?.should be true
          end

        end

      end
    end
  end
end
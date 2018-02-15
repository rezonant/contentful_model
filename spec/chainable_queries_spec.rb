require 'spec_helper'

class MockChainQueriable
  include ContentfulModel::Queries

  class << self
    attr_accessor :content_type_id
  end
end

class MockChainQueriableEntry < MockChainQueriable
  self.content_type_id = 'foo'

  def self.client
    @@client ||= MockClient.new
  end

  def self.client=(client)
    @@client = client
  end 

  def invalid?
    false
  end
end

describe ContentfulModel::ChainableQueries do
  subject { MockChainQueriableEntry }

  before do
    subject.content_type_id = 'foo'
  end

  describe 'class methods' do
    describe '::all' do
      it 'fails if no content type is set' do
        subject.content_type_id = nil
        expect { subject.all }.to raise_error 'You need to set self.content_type in your model class'
      end

      it 'returns itself' do
        expect(subject.all.parameters).to eq Hash.new
      end
    end

    it '::params' do
      expect(subject.params(abc: 123).parameters).to include('abc' => 123)
    end

    it '::first' do
      query = ContentfulModel::Query.new(subject)
      expect(query).to receive(:first) { 'first' }
      expect(subject).to receive(:query) { query }
      expect(subject.first).to eq 'first'
    end

    it '::skip' do
      query = subject.skip(2)
      expect(query.parameters).to include('skip' => 2)
    end

    it '::offset' do
      query = subject.offset(3)
      expect(query.parameters).to include('skip' => 3)
    end

    it '::limit' do
      query = subject.limit(4)
      expect(query.parameters).to include('limit' => 4)
    end

    it '::locale' do
      query = subject.locale('en-US')
      expect(query.parameters).to include('locale' => 'en-US')
    end

    it '::load_children' do
      query = subject.load_children(4)
      expect(query.parameters).to include('include' => 4)
    end

    describe '::order' do
      describe 'when parameter is a hash' do
        it 'ascending' do
          query = subject.order(foo: :asc)
          expect(query.parameters).to include('order' => 'fields.foo')
        end

        it 'descending' do
          query = subject.order(foo: :desc)
          expect(query.parameters).to include('order' => '-fields.foo')
        end
      end

      it 'when param is a symbol' do
        query = subject.order(:foo)
        expect(query.parameters).to include('order' => 'fields.foo')
      end

      it 'when param is a string' do
        query = subject.order('foo')
        expect(query.parameters).to include('order' => 'fields.foo')
      end

      it 'when param is a sys property' do
        query = subject.order(:created_at)
        expect(query.parameters).to include('order' => 'sys.createdAt')
      end
    end

    describe '::where' do
      it 'when value is an array' do
        subject.client = MockClient.new({ items: [ 1, 2, 3 ] })
        query = subject.where(foo: [1, 2, 3])
        expect(query.parameters).to include('fields.foo[in]' => '1,2,3')
      end

      it 'when field ends in _id, it should expand to .sys.id' do 
        query = subject.where(foo_id: 'abc')
        expect(query.parameters).to include('fields.foo.sys.id' => 'abc')
      end 

      it 'when value is a string' do
        query = subject.where(foo: 'bar')
        expect(query.parameters).to include('fields.foo' => 'bar')
      end

      it 'when value is a number' do
        query = subject.where(foo: 1)
        expect(query.parameters).to include('fields.foo' => 1)
      end

      it 'when value is a boolean' do
        query = subject.where(foo: true)
        expect(query.parameters).to include('fields.foo' => true)
      end

      it 'when value is a hash' do
        query = subject.where(foo: {gte: 123})
        expect(query.parameters).to include('fields.foo[gte]' => 123)
      end
    end

    describe '::search' do
      describe 'when parameter is a hash' do
        it 'when value is a string performs "match"' do
          query = subject.search(foo: 'bar')
          expect(query.parameters).to include('fields.foo[match]' => 'bar')
        end

        it 'when value is a hash performs query based on hash key' do
          query = subject.search(foo: {gte: 123})
          expect(query.parameters).to include('fields.foo[gte]' => 123)
        end
      end

      it 'when parameter is a string, performs full text search using "query"' do
        query = subject.search('foobar')
        expect(query.parameters).to include('query' => 'foobar')
      end
    end
  end
end

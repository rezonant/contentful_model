require 'spec_helper'

describe ContentfulModel::Query do
  let(:parameters) { { 'sys.id' => 'foo' } }
  let(:entry) { vcr('nyancat') { Cat.find('nyancat') } }
  subject { described_class.new(Cat, parameters) }

  describe 'attributes' do
    it ':parameters' do
      expect(subject.parameters).to eq parameters
    end
  end

  describe 'instance_methods' do
    before :each do
      ContentfulModel.configure do |config|
        config.space = 'cfexampleapi'
        config.access_token = 'b4c0n73n7fu1'
        config.entry_mapping = {}
      end

      Cat.client = nil
    end

    it '#params creates a new instance' do
      expect(subject.parameters).to eq parameters

      subquery = subject.params(foo: 'bar')
      expect(subquery).not_to be subject
      expect(subquery.parameters).to eq subject.parameters.merge(foo: 'bar')
    end

    it '#default_parameters' do
      expect(subject.default_parameters).to eq('content_type' => 'cat')
    end

    it '#client' do
      vcr('client') {
        expect(subject.client).to eq Cat.client
      }
    end

    describe '#advance' do
      it 'sets offset when none is present' do
        subquery = subject.advance(7)
        expect(subquery.parameters[:skip]).to eq 7
      end 
      it 'increases offset when one is present' do
        subquery = subject.offset(4).advance(7)
        expect(subquery.parameters[:skip]).to eq 11
      end 
      it 'decreases offset when one is present' do
        subquery = subject.offset(4).advance(-3)
        expect(subquery.parameters[:skip]).to eq 1
      end 
    end 

    describe '#first' do
      it 'returns the first result' do
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true
        expect(subject).to receive(:load) { [6] }
        expect(subject.first).to eq 6
        expect(subject.parameters[:limit]).to eq 1
      end 
    end   

    describe '#second' do
      it 'returns the second result' do
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true
        expect(subject).to receive(:load) { [3] }
        expect(subject.second).to eq 3
        expect(subject.parameters[:skip]).to eq 1
        expect(subject.parameters[:limit]).to eq 1
      end 
    end   

    describe '#third' do
      it 'returns the third result' do
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true
        expect(subject).to receive(:load) { [6] }
        expect(subject.third).to eq 6
        expect(subject.parameters[:skip]).to eq 2
        expect(subject.parameters[:limit]).to eq 1
      end 
    end

    describe '#fourth' do
      it 'returns the fourth result' do
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true
        expect(subject).to receive(:load) { [6] }
        expect(subject.fourth).to eq 6
        expect(subject.parameters[:skip]).to eq 3
        expect(subject.parameters[:limit]).to eq 1
      end 
    end   

    describe '#fifth' do
      it 'returns the fifth result' do
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true
        expect(subject).to receive(:load) { [6] }
        expect(subject.fifth).to eq 6
        expect(subject.parameters[:skip]).to eq 4
        expect(subject.parameters[:limit]).to eq 1
      end 
    end   

    describe '#forty_two' do
      it 'returns the forty_twoeth result' do
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true
        expect(subject).to receive(:load) { [4] }
        expect(subject.forty_two).to eq 4
        expect(subject.parameters[:skip]).to eq 41
        expect(subject.parameters[:limit]).to eq 1
      end 
    end   

    describe '#reverse' do 
      it 'should reverse the result array when no sort is specified' do
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 
        expect(subject).to receive(:execute) { [3,2,1] }
        result = subject.reverse.load
        expect(result).to eq [1,2,3]
      end 

      it 'should reverse the sort order when an order is already specified' do
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 
        subject.order(foo: :asc, bar: :desc)
        expect(subject).to receive(:load) { [3,2,1] }
        result = subject.reverse.load
        expect(result).to eq [3,2,1]
        expect(subject.parameters[:order]).to eq "-fields.foo,fields.bar"
      end 

      it 'should reverse the sort order when an order is already specified (case 2)' do
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 
        subject.order(foo: :desc, bar: :desc)
        expect(subject).to receive(:load) { [3,2,1] }
        result = subject.reverse.load
        expect(result).to eq [3,2,1]
        expect(subject.parameters[:order]).to eq "fields.foo,fields.bar"
      end 

      it 'should reverse the sort order when an order is already specified (case 2)' do
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 
        subject.order(foo: :asc, bar: :asc)
        expect(subject).to receive(:load) { [3,2,1] }
        result = subject.reverse.load
        expect(result).to eq [3,2,1]
        expect(subject.parameters[:order]).to eq "-fields.foo,-fields.bar"
      end 
    end 

    describe '#length' do
      it 'should execute the query and return the length of the result array' do 
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 
        expect(subject).to receive(:execute) { [1,64,22,564,432] }
        expect(subject.length).to eq 5
      end 
    end 

    describe '#each' do
      it 'should iterate over the results of the query' do 
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 

        results = [1,64,22,564,432]
        index = 0
        expect(subject).to receive(:execute) { results }
        subject.each do |i|
          expect(i).to eq(results[index])
          index += 1
        end 
      end 
    end 

    describe '#select' do
      it 'should iterate over the results of the query and filter' do 
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 

        results = [1,64,23,564,431]
        expected_filtered_results = [64, 564]

        expect(subject).to receive(:execute) { results }

        index = 0
        filtered_results = subject.select {|x| x % 2 == 0 }
        filtered_results.each do |i|
          expect(i).to eq(expected_filtered_results[index])
          index += 1
        end 
      end 
    end 

    describe '#reject' do
      it 'should iterate over the results of the query and filter' do 
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 

        results = [1,64,23,564,431]
        expected_filtered_results = [1, 23, 431]

        expect(subject).to receive(:execute) { results }

        index = 0
        filtered_results = subject.reject {|x| x % 2 == 0 }
        filtered_results.each do |i|
          expect(i).to eq(expected_filtered_results[index])
          index += 1
        end 
      end 
    end 


    describe '#map' do
      it 'should iterate over the results of the query and transform' do 
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 

        results = [1,64,23,564,431]
        expected_filtered_results = [2, 65, 24, 565, 432]

        expect(subject).to receive(:execute) { results }

        index = 0
        filtered_results = subject.map {|x| x + 1 }
        filtered_results.each do |i|
          expect(i).to eq(expected_filtered_results[index])
          index += 1
        end 
      end 
    end 

    describe '#to_a' do
      it 'should execute the query and return the results as a true array' do 
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 

        results = [1,64,23,564,431]
        expect(subject).to receive(:execute) { results }

        index = 0
        real_array = subject.to_a
        
        expect(real_array).to be_a(Array)
        expect(real_array.length).to be 5
        real_array.each do |i|
          expect(i).to be results[index]
          index += 1
        end 
      end 
    end

    describe '#[]' do 
      it 'should execute the query and return the nth result' do
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 

        results = [1,64,23,564,431]
        expect(subject).to receive(:execute) { results }

        index = 0
        results.each do |i|
          expect(subject[index]).to be i
          index += 1
        end 
      end 

      it 'should not execute the query multiple times' do 
        subject = ContentfulModel::Query.new(Cat)
        subject.mutable = true 

        expect(subject).to receive(:execute).once { [1,2,3,4,5] }

        subject[0]
        subject[0]
        subject[1]
        subject[2]
      end 
    end

    describe '#execute' do
      it 'when response is empty' do
        vcr('query/empty') {
          expect(subject.execute.items).to eq []
        }
      end

      it 'when response contains items' do
        query = described_class.new(Cat, 'sys.id' => 'nyancat')
        vcr('nyancat') {
          entries = query.execute
          expect(entries.first.id).to eq 'nyancat'
        }
      end
    end
  end
end

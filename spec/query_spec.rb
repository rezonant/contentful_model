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

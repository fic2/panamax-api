require 'spec_helper'

describe LocalImage do

  it_behaves_like 'an api model'

  let(:local_image1) do
    double(:local_image1,
      id: 'abc123',
      info: {
        'VirtualSize' => 111,
        'RepoTags' => [
          'foo/bar:latest',
          'foo/bar:1.0',
          'fizz:latest',
          'private:5000/bizzle:1.5'
        ]
      })
  end

  let(:local_image2) do
    double(:local_image2,
      id: 'xyz789',
      info: {
        'VirtualSize' => 222,
      })
  end

  let(:local_image3) do
    double(:local_image3,
      id: 'efg456',
      info: {
        'VirtualSize' => 333,
        'RepoTags' => ['panamax:latest']
      })
  end

  before do
    allow(Docker::Image).to receive(:all).and_return([local_image1, local_image2, local_image3])
  end

  describe 'attributes' do
    it { should respond_to :id }
    it { should respond_to :virtual_size }
    it { should respond_to :tags }
  end

  describe '#untagged?' do

    it 'returns true when id is <none>' do
      subject.id = described_class::UNTAGGED
      expect(subject).to be_untagged
    end

    it 'returns false when id is NOT <none>' do
      subject.id = 'foo'
      expect(subject).to_not be_untagged
    end
  end

  describe '.all' do

    it 'returns a result for each local image' do
      result = described_class.all

      expect(result).to be_kind_of(Array)
      expect(result.count).to eq 3
    end

    it 'returns LocalImage instances' do
      result = described_class.all.first

      expect(result).to be_kind_of(described_class)
      expect(result.id).to eq local_image1.id
      expect(result.virtual_size).to eq local_image1.info['VirtualSize']
      expect(result.tags).to eq local_image1.info['RepoTags']
    end
  end

  describe '.find' do

    context 'when the image exists' do

      it 'returns the result with the given ID' do
        result = described_class.find(local_image3.id)
        expect(result.id).to eq local_image3.id
      end
    end

    context 'when the image does NOT exist' do

      it 'returns nil' do
        expect(described_class.find('sparky')).to be_nil
      end
    end
  end

  describe '.destroy' do

    let(:id) { '123abc' }
    let(:image) { double(:image, delete: nil) }

    before do
      allow(Docker::Image).to receive(:get).and_return(image)
    end

    it 'retrieves the image' do
      expect(Docker::Image).to receive(:get).with(id)
      described_class.destroy(id)
    end

    it 'deletes the image' do
      expect(image).to receive(:delete)
      described_class.destroy(id)
    end

    it 'returns true' do
      expect(described_class.destroy(id)).to eq true
    end
  end

  describe '.all_by_repo' do

    it 'returns a result for each unique, tagged repo' do
      result = described_class.all_by_repo

      expect(result).to be_kind_of(Array)
      expect(result.count).to eq 4
      expect(result.map(&:id)).to match_array %w(foo/bar fizz panamax private:5000/bizzle)
    end

    it 'returns the tags for each repo' do
      result = described_class.all_by_repo.map(&:tags).flatten

      expect(result.count).to eq 5
      expect(result).to match_array %w(latest latest latest 1.5 1.0)
    end
  end

  describe '.find_by_name' do

    let(:name) { 'foo/bar' }

    it 'returns a LocalImage for the specified name' do
      result = described_class.find_by_name(name)

      expect(result).to be_kind_of(described_class)
      expect(result.id).to eq name
    end

    context 'when the specified name cannot be found' do

      it 'returns nil' do
        result = described_class.find_by_name('doesnotexist')
        expect(result).to be_nil
      end
    end
  end

  describe '.search' do

    let(:query) { 'f' }

    it 'returns LocalImages for all repos matching search' do
      result = described_class.search(query)

      expect(result).to be_kind_of(Array)
      expect(result.count).to eq 2
      expect(result.map(&:id)).to eq %w(foo/bar fizz)
    end

    context 'when a limit is provided' do

      let(:limit) { 1 }

      it 'returns only the specified number of results' do
        result = described_class.search(query, limit)
        expect(result.size).to eq limit
      end
    end
  end

  describe '.find_by_id_or_name' do

    context 'when queried by ID' do

      let(:key) { local_image3.id }

      it 'returns the LocalImage matching the provided ID' do
        result = described_class.find_by_id_or_name(key)
        expect(result).to be_kind_of(described_class)
        expect(result.id).to eq key
      end
    end

    context 'when queried by name' do

      let(:key) { 'foo/bar' }

      it 'returns a LocalImage matching the provided name' do
        result = described_class.find_by_id_or_name(key)
        expect(result).to be_kind_of(described_class)
        expect(result.id).to eq key
      end
    end
  end
end

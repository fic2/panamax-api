require 'spec_helper'

describe SharedVolumeServiceExistsValidator do

  let(:image_one) { Image.new(name: 'foo') }
  let(:image_two) { Image.new(name: 'bar') }
  let(:template) { Template.new(images: [image_one, image_two]) }
  let(:record) { Image.new(template: template) }
  let(:attribute) { 'volumes_from' }

  subject { described_class.new(attributes: [attribute]) }

  context 'when the attribute is valid' do

    let(:value) do
      [
        { 'service' => 'foo' },
        { 'service' => 'bar' }
      ]
    end

    it 'returns no errors for volumes_from with existing services' do
      subject.validate_each(record, attribute, value)
      expect(record.errors).to be_empty
    end

  end

  context 'when the attribute is not valid' do

    let(:value) do
      [
        { 'service' => 'baz' },
        { 'service' => 'quux' }
      ]
    end

    it 'should set an error on the record' do
      subject.validate_each(record, attribute, value)
      expect(record.errors).to_not be_empty
    end

    it 'should quit validating after the first error is detected' do
      subject.validate_each(record, attribute, value)
      expect(record.errors[attribute].size).to eq 1
    end

  end

end

require 'spec_helper'

describe CategorySerializer do
  let(:category_model) { AppCategory.new }

  it 'exposes the attributes to be jsonified' do
    serialized = described_class.new(category_model).as_json
    expected_keys = [
      :id,
      :name
    ]
    expect(serialized.keys).to match_array expected_keys
  end
end
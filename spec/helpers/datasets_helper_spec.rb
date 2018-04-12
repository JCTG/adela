require 'spec_helper'

describe DatasetsHelper do
  describe '#accrual_periodicity_translate' do
    it 'translates the accrual periodicity values' do
      ISO8601_DEFAULTS['accrual_periodicity'].each do |key, value|
        accrual_periodicity = helper.accrual_periodicity_translate(value)
        expect(accrual_periodicity).to eq(key)
      end
    end
  end

  describe '#documented_distributions' do
    it 'returns only documented distributions' do
      dataset = create(:dataset)
      create(:distribution, state: 'broke', dataset: dataset)
      create(:distribution, state: 'documented', dataset: dataset)
      create(:distribution, state: 'published', dataset: dataset)
      dataset.reload

      distributions = helper.documented_distributions(dataset)
      expect(distributions.count) == 2
    end
  end
end

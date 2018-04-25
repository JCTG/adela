require 'spec_helper'

describe Distribution do
  describe '#valid?' do
    let(:distribution) { create(:distribution) }

    it 'should be valid with all the mandatory fields' do
      expect(distribution).to be_valid
    end

    it 'should not be valid with a duplicated download_url' do
      new_distribution = build(:distribution, download_url: distribution.download_url)
      expect(new_distribution).not_to be_valid
    end

    it 'should not be valid with a duplicated title' do
      new_distribution = build(:distribution, title: distribution.title)
      expect(new_distribution).not_to be_valid
    end

    it 'should not be valid with higher modified that today' do
      new_distribution = build(:distribution, modified:Date.today.next_day(1))
    end
  end

  describe '#valid?(:ckan)' do
    let!(:distribution) { create(:distribution) }

    it 'should be valid with all the mandatory fields' do
      expect(distribution).to be_valid(:ckan)
    end

    it 'should not be valid without a title' do
      distribution.title = nil
      expect(distribution).not_to be_valid(:ckan)
    end

    it 'should not be valid without a description' do
      distribution.description = nil
      expect(distribution).to be_valid(:ckan)
    end

    it 'should not be valid without a download_url' do
      distribution.download_url = nil
      expect(distribution).not_to be_valid(:ckan)
    end

    it 'should not be valid without a publish_date' do
      distribution.publish_date = nil
      expect(distribution).to be_valid(:ckan)
    end

    it 'should not be valid without a format' do
      distribution.format = nil
      expect(distribution).not_to be_valid(:ckan)
    end

    it 'should not be valid without a modified' do
      distribution.modified = nil
      expect(distribution).to be_valid(:ckan)
    end

    it 'should be valid without a temporal' do
      allow(distribution).to receive(:temporal) { nil }

      expect(distribution).to be_valid(:ckan)
    end
  end

  describe '#as_csv' do
    let(:distribution) { create(:distribution_with_dataset) }

    it 'should return the csv file hash attributes' do
      expect(distribution.as_csv(style: :inventory)).eql?(
        {
          'Responsable': distribution.dataset.contact_position,
          'Nombre del conjunto': distribution.dataset.title,
          'Nombre del recurso': distribution.title,
          '¿De qué es?': distribution.description,
          '¿Tiene datos privados?': distribution.dataset.public_access ? 'Publico' : 'Privado',
          'Razón por la cual los datos son privados': nil,
          '¿En qué plataforma, tecnología, programa o sistema se albergan?': distribution.media_type,
          'Fecha estimada de publicación en datos.gob.mx': distribution.dataset.publish_date&.strftime('%F'),
        }
      )
    end

    it 'should return the hash attributes' do
      expect(distribution.as_csv).to eql(distribution.attributes)
    end
  end

  describe '#state' do
    let!(:distribution) { create(:distribution) }

    it 'should be broke by default' do
      distribution.download_url = nil # this makes valid?(:ckan) => false
      distribution.save
      expect(distribution.state).to eql('broke')
    end

    it 'should be documented if valid?(:ckan)' do
      expect(distribution.state).to eql('documented')
    end

    it 'should be refining if brokes after published' do
      distribution.update_attribute(:state, 'published')
      distribution.download_url = nil # this makes valid?(:ckan) => false
      distribution.save
      expect(distribution.state).to eql('refining')
    end

    it 'should be refined if valid?(:ckan) after refining ' do
      distribution.update_attribute(:state, 'refining')
      distribution.save
      expect(distribution.state).to eql('refined')
    end
  end

  context 'after commit' do
    let!(:distribution) { create(:distribution_with_dataset) }

    it 'should update the dataset modified with the latest distribution modified date' do
      dataset = distribution.dataset
      dataset.modified = Date.yesterday
      dataset.save

      distribution.modified = Date.today
      distribution.save
      dataset.reload

      expect(distribution.modified).to eq(dataset.modified)
    end
  end
end

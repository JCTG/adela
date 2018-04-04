require 'spec_helper'

describe Organization do
  context 'validations' do
    let(:organization) { create(:organization) }

    it 'should be valid with mandatory attributes' do
      expect(organization).to be_valid
    end

    it 'should be ranked by default' do
      expect(organization.ranked?).to be_truthy
    end

    it 'should be valid without ranking' do
      organization.ranked = false
      expect(organization).to be_valid
    end

    it 'should be valid with ranking' do
      organization.ranked = true
      expect(organization).to be_valid
    end


    it 'should not be valid without a title' do
      organization.title = nil
      expect(organization).not_to be_valid
    end

    it 'should not be valid without a description' do
      organization.description = nil
      expect(organization).not_to be_valid
    end

    it 'should not be valid without a landing_page' do
      organization.landing_page = nil
      expect(organization).not_to be_valid
    end

    it 'should not be valid without a gov_type' do
      organization.gov_type = nil
      expect(organization).not_to be_valid
    end

    it 'should not be valid with duplicated title' do
      new_organization = build(:organization, title: organization.title)
      expect(new_organization).not_to be_valid
    end

    it 'should be valid with duplicated landing_page' do
      new_organization = build(:organization, landing_page: organization.landing_page)
      expect(new_organization).to be_valid
    end
    
  end

  context 'defaults' do
    let(:organization) { create(:organization) }

    it 'should not be a ministry' do
      expect(organization.ministry?).to be false
    end
  end

  context 'scopes' do
    describe '::sector' do
      let(:organization) { create(:organization_with_sector) }

      it 'should return the collection of organization with a given sector' do
        rand(1..10).times { create(:organization) }
        sector = organization.sectors.first
        organizations = Organization.sector(sector.slug)
        expect(organizations.count).to eql(1)
      end
    end

    describe '::gov_type' do
      let!(:organization) { create(:federal_organization) }

      it 'should return the collection of organization with a given gov_type' do
        rand(1..10).times { create(:statal_organization) }
        organizations = Organization.gov_type('federal')
        expect(organizations.count).to eql(1)
      end
    end

    describe '::title_sorted' do
      it 'should return the collection of organization sorted by title' do
        (1..3).each { |n| create(:organization, title: "organization-#{n}") }
        organizations = Organization.title_sorted
        expect(organizations.map(&:title)).to eql(['organization-1', 'organization-2', 'organization-3'])
      end
    end
  end
end

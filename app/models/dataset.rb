class Dataset < ActiveRecord::Base
  include Publishable
  include DCATCommons
  include Auditable

  belongs_to :catalog

  has_many :distributions, dependent: :destroy

  has_one :dataset_sector, dependent: :destroy
  has_one :sector, through: :dataset_sector
  has_one :organization, through: :catalog

  accepts_nested_attributes_for :dataset_sector
  accepts_nested_attributes_for :distributions, allow_destroy: true

  validates_uniqueness_of :title
  validates :distributions, presence: true

  before_update :keyword_validation , if: :keyword?
  validate :validate_keyword_lengh , if: :keyword?

  with_options on: :inventory do |dataset|
    dataset.validates :title, :contact_position, :public_access, :publish_date, presence: true
  end

  with_options on: :catalog do |dataset|
    dataset.validates :description, :accrual_periodicity, :public_access, :publish_date, presence: true
  end

  with_options on: :ckan do |dataset|
    dataset.validates :title, :description, :accrual_periodicity, :mbox, 
                      :data_dictionary, presence: true
  end

  def identifier
    title.to_slug.normalize.to_s
  end

  def publisher
    catalog.organization.title
  end

  def keywords
    keywords = []
    keywords.push(*keyword&.split(','))
    keywords.push(*sectors.split(','))
    keywords.compact.join(',')
  end

  def keyword_validation
      array = keyword.split(',')
      quote_doble = "\"";
      quote_simple = "\'";
      array.select { |item| item.to_s.delete! quote_doble  }
      array.select { |item| item.to_s.delete! quote_simple }
      array.select { |item| item.to_s.strip! }
      array.delete_if {|item| item.length == 0 }
      array.map!(&:downcase)
      array.each { |item|      
      item.gsub!(" ", "-")
      }
      self.keyword.clear
      array.each { |item|      
      if self.keyword.length == 0 then
        self.keyword =  item
      else
        self.keyword = self.keyword + "," + item
      end
      }
    return self.keyword
  end


  def openess_rating
    formats = distributions.map(&:format)
    case
    when formats.grep(/^(xls|xlsx)$/i).present?
      2
    when formats.grep(/^(csv|tsv|psv|json|shp|kml|kmz|xml)$/i).present?
      3
    when formats.grep(/^(rdf)$/i).present?
      4
    when formats.grep(/^(lod)$/i).present?
      5
    else
      1
    end
  end

  private
    def sectors
      catalog.organization.sectors.map(&:slug).join(',')
    end

    def gov_type
      catalog.organization&.gov_type
    end

    def validate_keyword_lengh
     array = self.keyword.split(',') 
      if array.select { |item| item.length > 25 }.size > 0 then
         errors.add(:keyword, "la longitud máxima exede a 25 caracteres: #{array.select { |item| item.length > 25 }}")
       end
    end
end

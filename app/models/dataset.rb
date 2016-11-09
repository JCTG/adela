class Dataset < ActiveRecord::Base
  include Versionable
  include Publishable

  belongs_to :catalog

  has_associated_audits
  audited associated_with: :catalog

  has_many :distributions, dependent: :destroy

  has_one :dataset_sector, dependent: :destroy
  has_one :sector, through: :dataset_sector
  has_one :organization, through: :catalog

  accepts_nested_attributes_for :dataset_sector
  accepts_nested_attributes_for :distributions, allow_destroy: true

  validates_uniqueness_of :title
  validates :distributions, presence: true

  validate :validate_temporal

  with_options on: :inventory do |dataset|
    dataset.validates :title, :contact_position, :public_access, :publish_date, presence: true
  end

  with_options on: :catalog do |dataset|
    dataset.validates :description, :accrual_periodicity, :public_access, :publish_date, presence: true
  end

  with_options on: :ckan do |dataset|
    dataset.validates :title, :description, :accrual_periodicity, :publish_date,
                      :contact_position, :mbox, :temporal, :sector, :keyword,
                      :landing_page, presence: true
  end

  def identifier
    title.to_slug.normalize.to_s
  end

  def publisher
    catalog.organization.title
  end

  def keywords
    "#{keyword},#{gov_type},#{sectors}".chomp(',').lchomp(',').downcase.strip
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
      catalog.organization.gov_type
    end

  def validate_temporal
      arrayDates = temporal.split('/')
      puts ("<<<<<<<<< Temporal >>>>>>>>>>>>>>>>>>>"   +  temporal)
      puts ("<<<<<<<<< la fecha inicial >>>>>>>>>>>" + arrayDates[0])
      puts ("<<<<<<<<< la fecha final >>>>>>>>>>>>>>>>>>>"   + arrayDates[1])

     if(  arrayDates     != nil &&  
           arrayDates[0] != nil && arrayDates[1] != nil  && 
           arrayDates[0] >= arrayDates[1] )
           puts("Periodo inicial " + arrayDates[0] +  " es mayor a periodo final " + arrayDates[1])         
           #la siguiente linea proboca el error en la pantalla Documenta tus Conjuntos y Recursos de Datos Abiertos no muestra el registro
           errors.add(:temporal, ' La fecha inicial es mayor que la fecha final ')            
      end

  end

end

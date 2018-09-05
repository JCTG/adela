module DCATCommons
  extend ActiveSupport::Concern

  included do
    validate :validate_temporal_range, if: :temporal_present?
  end

  def temporal
    return unless temporal_present?

    "#{temporal_init_date.iso8601}/#{temporal_term_date.iso8601}"
  end

  def validate_temporal_range
    return if temporal_init_date < temporal_term_date

    errors.add(:La_fecha, temporal_invalid_error_message)
  end

  def temporal_present?
    temporal_init_date && temporal_term_date
  end

  def temporal_invalid_error_message
    model_name = self.class.name.downcase
    I18n.t("activerecord.errors.models.#{model_name}.attributes.temporal.invalid")
  end
end

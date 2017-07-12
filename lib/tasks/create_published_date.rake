desc 'Create init date and end dates'
task create_init_and_end_date: :environment do
  Dataset.where.not(temporal: nil).map do |dataset|
      begin
        temporal = dataset.temporal.split('/').map do |date|
          ISO8601::Date.new(date)
        end

        dataset.update(
          temporal_init_date: temporal[0].to_s,
          temporal_init_date: temporal[1].to_s
        )
      rescue ISO8601::Errors::UnknownPattern
        next
      end
    end

    Distribution.where.not(temporal: nil).map do |distribution|
      begin
        temporal = distribution.temporal.split('/').map do |date|
          ISO8601::Date.new(date)
        end

        distribution.update(
          temporal_init_date: temporal[0].to_s,
          temporal_init_date: temporal[1].to_s
        )
      rescue ISO8601::Errors::UnknownPattern
        next
      end
    end

end
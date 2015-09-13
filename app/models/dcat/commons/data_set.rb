module DCAT
  module Commons
    module DataSet

      attr_accessor :distributions, :publisher, :identifier, :title, :description,
        :keyword, :modified, :contactPoint, :mbox, :accessLevel, :accessLevelComment,
        :temporal, :spatial, :accrualPeriodicity

      def initialize(attributes = {})
        @distributions = []
        attributes.each do |name, value|
          if value.present?
            send("#{name}=", value.force_encoding(Encoding::UTF_8).strip)
          end
        end
      end

      def private?
        ['privado', 'restringido'].include? accessLevel
      end

      def keywords
        keyword.to_s.split(",").map(&:strip).reject{ |k| k.empty? }
      end

      def distributions_count
        distributions.size
      end
    end
  end
end
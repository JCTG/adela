module Publishable
  extend ActiveSupport::Concern

  included do
    before_save :fix_resource
    before_save :break_resource
    before_save :break_published_resource
    before_save :fix_published_resource

    state_machine initial: :broke do
      state :broke
      state :documented
      state :refining
      state :refined
      state :published

      event :document do
        transition [:broke] => :documented, if: lambda { |resource| resource.compliant? }
      end

      event :break_resource do
        transition [:documented] => :broke, unless: lambda { |resource| resource.compliant? }
      end

      event :break_published_resource do
        transition [:published] => :refining, unless: lambda { |resource| resource.compliant? }
      end

      event :refine_published_resource do
        transition [:published, :refining] => :refined, if: lambda { |resource| resource.compliant? }
      end
    end
  end

  def fix_resource
    document if can_document?
  end

  def break_resource
    break_resource if can_break_resource?
  end

  def break_published_resource
    refine_published_resource if can_refine_published_resource?
  end

  def fix_published_resource
    break_published_resource if can_break_published_resource?
  end
end

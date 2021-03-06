class ActivityLog < ActiveRecord::Base

  belongs_to :organization

  scope :date_sorted, -> { order("activity_logs.done_at DESC") }
  scope :first_block, -> { date_sorted.limit(5) }
  scope :last_block, -> { date_sorted.limit(10).offset(5) }
end

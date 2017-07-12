class NormalizeTemporalField < ActiveRecord::Migration
  def change
    add_column :datasets, :temporal_init_date, :datetime
    add_column :datasets, :temporal_term_date, :datetime

    add_column :distributions, :temporal_init_date, :datetime
    add_column :distributions, :temporal_term_date, :datetime
  end
end

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # In a bare ActiveRecord setup (outside Rails) this defaults to nil/false, so
  # a stay without a room would pass validation and crash on the DB NOT NULL
  # constraint. Restore the standard Rails behaviour: belongs_to is required.
  self.belongs_to_required_by_default = true
end

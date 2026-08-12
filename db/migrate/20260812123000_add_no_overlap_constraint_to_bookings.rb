class AddNoOverlapConstraintToBookings < ActiveRecord::Migration[8.1]
  def up
    enable_extension "btree_gist"
    add_exclusion_constraint :bookings,
                             "room_id WITH =, daterange(check_in, check_out) WITH &&",
                             using: :gist,
                             where: "status <> 'cancelled'",
                             name: "no_overlapping_bookings"
  end

  def down
    remove_exclusion_constraint :bookings, name: "no_overlapping_bookings"
    disable_extension "btree_gist"
  end
end

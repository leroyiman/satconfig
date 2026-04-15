class Admin::DashboardController < Admin::BaseController
  def index
    @stats = {
      cities:               City.count,
      locations:            Location.active.count,
      conference_rooms:     ConferenceRoom.active.count,
      offices:              Office.active.count,
      virtual_offices:      VirtualOffice.active.count,
      company_headquarters: CompanyHeadquarter.active.count,
      addons:               Addon.active.count
    }

    @overrides_count = Product.where("local_attributes != '{}'::jsonb").count

    @recent_syncs = Product.where.not(last_synced_at: nil)
                           .order(last_synced_at: :desc)
                           .limit(8)
                           .includes(location: :city)
  end
end

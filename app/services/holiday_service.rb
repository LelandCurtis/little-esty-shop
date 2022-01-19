require 'httparty'
require 'json'

class HolidayService

  def self.get_upcomming_holidays(holiday_count)
    all_holidays = get_url("NextPublicHolidays/US")
  end

  def self.get_url(url)
    response = HTTParty.get("https://date.nager.at/api/v3/#{url}")
    parsed = JSON.parse(response.body, serialize_names: true)
  end
end

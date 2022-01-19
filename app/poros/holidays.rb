#require_relative 'holiday'
class Holidays

  attr_reader :holidays

  def initialize(holiday_count)

    upcomming_holiday_data = HolidayService.get_upcomming_holidays(3)
    upcomming_holidays = upcomming_holiday_data[0..(holiday_count - 1)]
    @holidays = upcomming_holidays.map{|data| Holiday.new(data)}
  end
end

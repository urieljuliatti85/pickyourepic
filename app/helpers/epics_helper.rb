module EpicsHelper
  def number_to_duration(milliseconds)
    return "—" if milliseconds.nil?

    total_seconds = milliseconds / 1000
    minutes = total_seconds / 60
    seconds = total_seconds % 60

    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end
end

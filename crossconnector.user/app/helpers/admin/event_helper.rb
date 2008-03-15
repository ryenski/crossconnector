module Admin::EventHelper
  
  def time_away(until_date)
    from_now = until_date > Time.now ? "from now" : "ago"
    case until_date
    when 0..4
      "#{distance_of_time_in_words_to_now(until_date)} #{from_now}"
    else
      "#{distance_of_time_in_weeks_to(until_date)} weeks #{from_now}"
    end
  end
  
  def event_date_and_time_for(event)
    return if event.start_date.nil?
    
    # If end_date is not set, set it to the start_date
    event.end_date ||= event.start_date
    #event.end_date.day ||= event.start_date.day
    #event.end_date.month ||= event.start_date.month
    
    # Jan 01
    content = "#{event.start_date.strftime("%B")} #{event.start_date.day}"
    
    if event.end_date == event.start_date
      content << ", #{event.start_date.year}"
    elsif event.end_date.day == event.start_date.day
      # Jan 01, 2006 from 12:00 pm to 4:00 pm
      content << ", #{event.start_date.year} from #{event.start_date.strftime("%I:%M %p")} to #{event.end_date.strftime("%I:%M %p")}"
    elsif event.end_date.month == event.start_date.month
      # Jan 01 to Jan 6, 2006
      content << " to #{event.end_date.strftime("%B %d, %Y")}"
    else
      # Dec 30, 2005 to Jan 6, 2006
      content << ", #{event.start_date.year} to #{event.end_date.strftime("%B %d, %Y")}"
    end
 
    content_tag("abbr", content, :title => "#{event.start_date.strftime("%Y%m%dT%H%M")}-0700", :class => "dtstart" )
    
  end
  
  def same_day?(date1,date2)
    return true if date1.year == date2.year and date1.month == date2.month and date1.day == date2.day
    return false
  end
  
  def select_12_hour_clock(datetime=Time.now, options = {})
    hour_options = []
    
    1.upto(12) do |hour|
       hour_options << ((datetime && (datetime.kind_of?(Fixnum) ? datetime : datetime.hour) == hour) ?
         %(<option value="#{leading_zero_on_single_digits(hour)}" selected="selected">#{leading_zero_on_single_digits(hour)}</option>\n) :
         %(<option value="#{leading_zero_on_single_digits(hour)}">#{leading_zero_on_single_digits(hour)}</option>\n)
       )
     end

     select_html(options[:field_name] || 'hour', hour_options, options[:prefix], options[:include_blank], options[:discard_type], options[:disabled])

  end
  
  def timeframe_to(date)
    case distance_of_time_in_weeks_to date 
      when 0  then    'thisweek'
      when 1..3 then  'withinthreemonths'
      when 4..26 then 'withinsixmonths'
      else            'sixmonthsormore'
    end
  end
  
  def distance_of_time_in_weeks_to(date)
    ((distance_of_time_in_days_to date)/7).to_i
  end
  
  def distance_of_time_in_days_to(date)
    ((date - Time.now).abs/60/1440).round.to_i
  end
  
  def distance_of_time_in_years_to(date)
  end
  
  
  
  def hcalendar_date(event)
    # Saturday, October 22, 2005
    content = content_tag("abbr", event.start_date.strftime("%A, %B %d, %Y"), :class => "dtstart", :title => event.start_date.strftime("%Y%m%d"))
    
    
    #<abbr class="dtstart" title="20051022"> October 22 </abbr> -
    #<abbr class="dtend" title="20051028"> 28, 2005 </abbr>
    
    #<abbr class="dtstart" title="20051022"> October 22 </abbr> - 
    #<abbr class="dtend" title="20051128"> November 28, 2005 </abbr>
    
  end


end

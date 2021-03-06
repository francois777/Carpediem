class TariffsController < ApplicationController

  include ApplicationHelper

  def summary
    @accTypes = AccommodationType.to_hash
    @accNames = AccommodationType::ACCOMMODATION_NAMES
    unless AccommodationType.any? || Tariff.any?
      redirect_to root_path 
      return
    end
    promotions = AccommodationType.promotions
    if promotions.any?
      @promotion_header = header_line(:promotion)
      @promotion_dtl_lines = tariff_details(:promotion)
    end  
    normal_prices = AccommodationType.normal_prices
    in_season_prices = AccommodationType.in_season_prices

    format_content_for_no_powerpoint_sites
    format_content_for_powerpoint_sites
    format_content_for_daily_visitors
    format_content_for_chalets
    format_content_for_groups
  end

  def detail_lines(accID, accType)
    lines = []
    tariffs = accType.tariffs
    lines.push(accType.tariffs.normal_price) if options(accID)[:normal_prices]
  end

  def site_tariffs(tariff, options = {})
    tariff_local_amount = to_local_currency(tariff.tariff)
    if options[:type] == :tent
      col1 = t(:tent_sites, scope: [:accommodation, :title_columns]).upcase
    else  
      col1 = t(:caravan_sites, scope: [:accommodation, :title_columns]).upcase
    end  
    col2 = tariff_local_amount
    col3 = t(:site_person_tariff, scope: [:accommodation, :tariff_2_columns], 
      adult_tariff: tariff_local_amount, 
      child_age_from: @settings.child_age_range.begin.to_s,
      child_age_to: @settings.child_age_range.end.to_s,
      child_tariff: to_local_currency(tariff.tariff * @settings.child_discount_percentage)
      )
    col4 = t(:site_limit, scope: [:accommodation, :restriction_columns])
    [col1, col2, col3, col4]
  end

  def day_visitor_tariffs(tariff)
    tariff_local_amount = to_local_currency(tariff.tariff)
    col1 = t(:day_visitors, scope: [:accommodation, :title_columns]).upcase
    col2 = t(:reference, scope: [:accommodation], num: "1")
    col3 = t(:site_person_tariff, scope: [:accommodation, :tariff_2_columns], 
      adult_tariff: tariff_local_amount, 
      child_age_from: @settings.child_age_range.begin.to_s,
      child_age_to: @settings.child_age_range.end.to_s,
      child_tariff: to_local_currency(tariff.tariff * @settings.child_discount_percentage)
      )
    col4 = t(:day_visitor_times, scope: [:accommodation, :restriction_columns], 
               in_time: @settings.day_visitor_in_time,
               out_time: @settings.day_visitor_out_time)
    [col1, col2, col3, col4]
  end

  def warrior_tariffs(tariff)
    tariff_local_amount = to_local_currency(tariff.tariff)
    col1 = t(:warrior_camps, scope: [:accommodation, :title_columns]).upcase
    col2 = ""
    col3 = t(:group_reservations, scope: [:accommodation, :tariff_2_columns], amount: tariff_local_amount)
    col4 = t(:friday_to_sunday, scope: [:accommodation, :restriction_columns], 
               in_time: @settings.day_visitor_in_time,
               out_time: @settings.day_visitor_out_time)
    [col1, col2, col3, col4]
  end

  def chalet_tariffs(tariff, options = {})
    tariff_local_amount = to_local_currency(tariff.tariff)
    case options[:type]
    when :small
      col1 = t(:chalet_small, scope: [:accommodation, :title_columns]).upcase
      col3 = t(:chalet_tariff, scope: [:accommodation, :tariff_2_columns], amount: tariff_local_amount, capacity: '4')
    when :medium  
      col1 = t(:chalet_medium, scope: [:accommodation, :title_columns]).upcase
      col3 = t(:chalet_tariff, scope: [:accommodation, :tariff_2_columns], amount: tariff_local_amount, capacity: '8')
    when :large
      col1 = t(:chalet_large, scope: [:accommodation, :title_columns]).upcase
      col3 = t(:chalet_tariff, scope: [:accommodation, :tariff_2_columns], amount: tariff_local_amount, capacity: '14')
    end
    col2 = ""
    col4 = t(:chalet_times, scope: [:accommodation, :restriction_columns], 
               in_time: @settings.day_visitor_in_time,
               out_time: @settings.day_visitor_out_time,
               ref: '2'
            )
    [col1, col2, col3, col4]
  end

  def group_tariffs(tariff, options = {})
    tariff_local_amount = to_local_amount(tariff.tariff)
    if options[:type] == :small
      col1 = t(:group_reservations_budget, scope: [:accommodation, :title_columns]).upcase
    else  
      col1 = t(:group_reservations_meals, scope: [:accommodation, :title_columns]).upcase
    end
    col2 = t(:reference, scope: [:accommodation], num: "3")
    col3 = t(:group_reservations, scope: [:accommodation, :tariff_2_columns], amount: tariff_local_amount)
    col4 = t(:friday_to_sunday, scope: [:accommodation, :restriction_columns], 
               in_time: @settings.tents_and_caravans_checkin_time,
               out_time: @settings.tents_and_caravans_checkout_time,
               remain_on_premises_time: @settings.remain_on_premises_time )
    [col1, col2, col3, col4]
  end

  private 

    def format_content_for_no_powerpoint_sites
      @no_power_header = header_line(:without_power_points)
      @no_power_dtl_lines = []
      @dtl_lines = []
      if show_tent_sites_without_power?
        accID = @accNames[:tent_site_without_power]
        accType = AccommodationType.where('accom_type=?',accID).first
        tariff_record = accType.tariffs.normal_price.first
        @dtl_lines = site_tariffs(tariff_record, {type: :tent} )
        @no_power_dtl_lines.push(@dtl_lines) 
      end   
      if show_caravan_sites_without_power?
        accID = @accNames[:caravan_site_without_power]
        accType = AccommodationType.where('accom_type=?',accID).first
        tariff_record = accType.tariffs.normal_price.first     
        @dtl_lines = site_tariffs(tariff_record, {type: :caravan} )
        @no_power_dtl_lines.push(@dtl_lines) 
      end   
      if show_king_and_warrior_camps?
        accID = @accNames[:king_and_warrior_camps]
        accType = AccommodationType.where('accom_type=?',accID).first
        tariff_record = accType.tariffs.first
        @dtl_lines = warrior_tariffs(tariff_record)
        @no_power_dtl_lines.push(@dtl_lines) 
      end
    end

    def format_content_for_powerpoint_sites
      @power_header = header_line(:powered_tariff)
      @power_dtl_lines = []
      @dtl_lines = []
      if show_tent_sites_with_power?
        accID = @accNames[:tent_site_with_power]
        accType = AccommodationType.where('accom_type=?',accID).first
        tariff_record = accType.tariffs.normal_price.first
        @dtl_lines = site_tariffs(tariff_record, {type: :tent} )
        @power_dtl_lines.push(@dtl_lines) 
      end   
      if show_caravan_sites_with_power?
        accID = @accNames[:caravan_site_with_power]
        accType = AccommodationType.where('accom_type=?',accID).first
        tariff_record = accType.tariffs.normal_price.first     
        @dtl_lines = site_tariffs(tariff_record, {type: :caravan} )
        @power_dtl_lines.push(@dtl_lines) 
      end   
      @power_detail_lines = [@dtl_lines]
    end

    def format_content_for_daily_visitors
      @day_visitor_dtl_lines = []
      @day_visitor_header = header_line(:day_visitor)
      @dtl_lines = []
      if show_day_visitors?    
        accID = @accNames[:day_visitor]
        accType = AccommodationType.where('accom_type=?',accID).first
        tariff_record = accType.tariffs.first     
        @dtl_lines = day_visitor_tariffs(tariff_record)
        @day_visitor_dtl_lines.push(@dtl_lines) 
      end
    end

    def format_content_for_chalets
      @chalet_header = header_line(:chalet_tariff)
      @chalet_dtl_lines = []
      if show_small_chalets?
        accID = @accNames[:chalet_small]
        accType = AccommodationType.where('accom_type=?',accID).first
        tariff_record = accType.tariffs.first     
        @dtl_lines = chalet_tariffs(tariff_record, {type: :small})
        @chalet_dtl_lines.push(@dtl_lines) 
      end
      if show_medium_chalets?
        accID = @accNames[:chalet_medium]
        accType = AccommodationType.where('accom_type=?',accID).first
        tariff_record = accType.tariffs.first     
        @dtl_lines = chalet_tariffs(tariff_record, {type: :medium})
        @chalet_dtl_lines.push(@dtl_lines) 
      end
      if show_large_chalets?
        accID = @accNames[:chalet_large]
        accType = AccommodationType.where('accom_type=?',accID).first
        tariff_record = accType.tariffs.first     
        @dtl_lines = chalet_tariffs(tariff_record, {type: :large})
        @chalet_dtl_lines.push(@dtl_lines) 
      end
    end

    def format_content_for_groups
      @groups_header = header_line(:group_tariff)
      @group_dtl_lines = []
      if show_group_tariffs_budget?
        accID = @accNames[:group_tariff_budget]
        accType = AccommodationType.where('accom_type=?',accID).first
        tariff_record = accType.tariffs.first
        @dtl_lines = group_tariffs(tariff_record, {type: :small})
        @group_dtl_lines.push(@dtl_lines) 
      end
      @groups_dtl_lines = []
      if show_group_tariffs_meals_included?
        accID = @accNames[:group_tariff_with_meals]
        accType = AccommodationType.where('accom_type=?',accID).first
        tariff_record = accType.tariffs.first     
        @dtl_lines = group_tariffs(tariff_record, {type: :medium})
        @group_dtl_lines.push(@dtl_lines) 
      end
    end
  
    def show_tent_sites_without_power?
      @accTypes[@accNames[:tent_site_without_power]] && 
        @accTypes[@accNames[:tent_site_without_power]]['show'] == true
    end

    def show_tent_sites_with_power?
      @accTypes[@accNames[:tent_site_with_power]] &&
        @accTypes[@accNames[:tent_site_with_power]]['show'] == true
    end

    def show_caravan_sites_without_power?
      @accTypes[@accNames[:caravan_site_without_power]] &&
        @accTypes[@accNames[:caravan_site_without_power]]['show'] == true
    end

    def show_caravan_sites_with_power?
      @accTypes[@accNames[:caravan_site_with_power]] &&
        @accTypes[@accNames[:caravan_site_with_power]]['show'] == true
    end

    def show_king_and_warrior_camps?
      @accTypes[@accNames[:king_and_warrior_camps]] &&
        @accTypes[@accNames[:king_and_warrior_camps]]['show'] == true
    end

    def show_day_visitors?
      @accTypes[@accNames[:day_visitor]] &&
        @accTypes[@accNames[:day_visitor]]['show'] == true
    end

    def show_small_chalets?
      @accTypes[@accNames[:chalet_small]] &&
        @accTypes[@accNames[:chalet_small]]['show'] == true
    end

    def show_medium_chalets?
      @accTypes[@accNames[:chalet_medium]] &&
        @accTypes[@accNames[:chalet_medium]]['show'] == true
    end

    def show_large_chalets?
      @accTypes[@accNames[:chalet_large]] &&
        @accTypes[@accNames[:chalet_large]]['show'] == true
    end

    def show_group_tariffs_budget?
      @accTypes[@accNames[:group_tariff_budget]] &&
        @accTypes[@accNames[:group_tariff_budget]]['show'] == true
    end

    def show_group_tariffs_meals_included?
      @accTypes[@accNames[:group_tariff_with_meals]] &&
        @accTypes[@accNames[:group_tariff_with_meals]]['show'] == true
    end

    def header_line(accommodation_type)
      case accommodation_type
      when :promotion
        [ "", "", "", ""] 
      when :without_power_points
        [ t(:without_power_points, scope: [:accommodation]).upcase,
          t(:per_site, scope: [:accommodation]).upcase,
          t(:per_person_per_night, scope: [:accommodation]).upcase,
          ""
        ]
      when :powered_tariff
        [ t(:with_power_points, scope: [:accommodation]).upcase,
          t(:per_site, scope: [:accommodation]).upcase,
          t(:per_person_per_night, scope: [:accommodation]).upcase,
          ""
        ]
      when :day_visitor
        [ "", "", t(:per_person, scope: [:accommodation]).upcase, ""]
      when :chalet_tariff
        [ "",
          "",
          t(:per_night_for_chalet, scope: [:accommodation]).upcase,
          ""
        ]
      when :group_tariff
        [ t(:without_power_points, scope: [:accommodation]).upcase,
          "",
          t(:per_person, scope: [:accommodation]).upcase,
          t(:tents_and_caravans, scope: [:accommodation]).upcase
        ]
      else
       [ "", "", "", ""]  
      end
    end

    def tariff_details(accommodation_type)
      case accommodation_type
      when :promotion
        if AccommodationType.where(show: true)
          [ "", "", "", ""]  
        else
          [ "", "", "", ""]
        end    
      end  
    end

end
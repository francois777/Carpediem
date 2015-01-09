class ReservationRequestsController < ApplicationController

  include ReservationRequestsHelper

  before_action :set_reservation_request, only: [:show, :edit, :update]
  before_action :set_types, only: [:new, :edit]

  def new
    @reservation_request = ReservationRequest.new
    @unavailable_facilities = []
  end

  def create
    @reservation_request = ReservationRequest.new(request_params)

    @unavailable_facilities = []
    if @reservation_request.valid?
      @unavailable_facilities = list_unavailable_facility_types
      # puts "Unavailable facilities: #{@unavailable_facilities.to_s}"
      if @unavailable_facilities.empty?
        @reservation_request.status = 'Pending'
        if @reservation_request.save
          flash[:success] = t(:reservation_request_created, scope: [:success])
          redirect_to edit_reservation_request_path(@reservation_request)
          return
        else
          flash[:alert] = t(:reservation_request_create_failed, scope: [:failure])
        end
      else
        flash[:alert] = t(:some_facilities_fully_booked, scope: [:failure])
      end  
    else
      flash[:alert] = t(:reservation_request_create_failed, scope: [:failure])
    end
    set_types
    render :new
  end

  def update
    puts "ReservationRequestsController#update"
    #puts params['update']

    @unavailable_facilities = []
    if @reservation_request.valid?
      @unavailable_facilities = list_unavailable_facility_types
      if @unavailable_facilities.empty?
        if @reservation_request.update_attributes(request_params)
          if params['update'] == 'Save and Review'
            flash[:success] = t(:reservation_request_updated, scope: [:success])
            redirect_to edit_reservation_request_path(@reservation_request)
            return
          else
            puts "\nReservation must now be created"
            puts "create_request_notification"
            render :show
            return
          end
        else
          flash[:alert] = t(:reservation_request_update_failed, scope: [:failure])
        end
      else
        flash[:alert] = t(:some_facilities_fully_booked, scope: [:failure])
      end  
    else
      flash[:alert] = t(:reservation_request_create_failed, scope: [:failure])
    end
    set_types
    render :edit
  end

  def validate_request
  end

  def submit
    puts "ReservationRequestsController#submit"
    # Validate request
    # Generate missing fields
    # Save request
    # Generate emails
    # Display confirmation page with Reservation Number
  end

  def show
  end

  def edit
    puts "ReservationRequestsController#edit"
    fac_cat_inx = @reservation_request.facility_type_1
    fac_cat_name = ReservationRequest.index_to_name(fac_cat_inx)
    dte_from = @reservation_request.start_date_1
    dte_until = @reservation_request.end_date_1
    powered = @reservation_request.power_point_required_1
    adult_tariff = Tariff.adult_tariff(fac_cat_name, dte_from, dte_until, powered)
    @adult_amount_1 = @reservation_request.adults_18_plus_count_1 * adult_tariff
    @teenagers_amount_1 = @reservation_request.teenagers_count_1 * adult_tariff
    @children_amount_1 = (@reservation_request.children_6_12_count_1 * adult_tariff * (1 - @settings.child_discount_percentage)).round
    @total_amount_1 = @adult_amount_1 + @teenagers_amount_1 + @children_amount_1
    @unavailable_facilities = []
    set_counters
    calculate_cost_for_facility_2 if @reservation_request.start_date_2.is_a? Time
    calculate_cost_for_facility_3 if @reservation_request.start_date_3.is_a? Time
  end

  private

    def request_params
      params.require(:reservation_request).permit(:applicant_name, :applicant_telephone,
        :applicant_mobile, :applicant_email, :applicant_town, :facility_type_1,
        :start_date_1, :end_date_1, :adults_18_plus_count_1, :teenagers_count_1,
        :children_6_12_count_1, :infants_count_1, :power_point_required_1,
        :facility_type_2, :start_date_2, :end_date_2, :adults_18_plus_count_2,
        :teenagers_count_2, :children_6_12_count_2, :infants_count_2,
        :power_point_required_2, :facility_type_3, :start_date_3, :end_date_3,
        :adults_18_plus_count_3, :teenagers_count_3, :children_6_12_count_3,
        :infants_count_3, :power_point_required_3, :meals_required_count,
        :vehicle_registration_numbers, :payable_amount, :key_deposit_amount,
        :estimated_arrival_time, :special_requests
        )
    end

    def set_reservation_request
      @reservation_request = ReservationRequest.find(params[:id].to_i)
    end

    def set_types
      @facility_types = I18n.t(:facility_types).each_with_index.map { |fType, inx| [fType[1].to_s, inx] }
    end

    def calculate_cost_for_facility_2
      puts "ReservationRequestsController#calculate_cost_for_facility_2"
      fac_cat_inx = @reservation_request.facility_type_2
      fac_cat_name = ReservationRequest.index_to_name(fac_cat_inx)
      dte_from = @reservation_request.start_date_2
      dte_until = @reservation_request.end_date_2
      powered = @reservation_request.power_point_required_2
      adult_tariff = Tariff.adult_tariff(fac_cat_name, dte_from, dte_until, powered)
      @adult_amount_2 = @reservation_request.adults_18_plus_count_2 * adult_tariff
      @teenagers_amount_2 = @reservation_request.teenagers_count_2 * adult_tariff
      @children_amount_2 = (@reservation_request.children_6_12_count_2 * adult_tariff * (1 - @settings.child_discount_percentage)).round
      @total_amount_2 = @adult_amount_2 + @teenagers_amount_2 + @children_amount_2
    end

    def calculate_cost_for_facility_3
      fac_cat_inx = @reservation_request.facility_type_3
      fac_cat_name = ReservationRequest.index_to_name(fac_cat_inx)
      dte_from = @reservation_request.start_date_3
      dte_until = @reservation_request.end_date_3
      powered = @reservation_request.power_point_required_3
      adult_tariff = Tariff.adult_tariff(fac_cat_name, dte_from, dte_until, powered)
      @adult_amount_3 = @reservation_request.adults_18_plus_count_3 * adult_tariff
      @teenagers_amount_3 = @reservation_request.teenagers_count_3 * adult_tariff
      @children_amount_3 = (@reservation_request.children_6_12_count_3 * adult_tariff * (1 - @settings.child_discount_percentage)).round
      @total_amount_3 = @adult_amount_3 + @teenagers_amount_3 + @children_amount_3
    end

    def set_counters
      @adult_amount_2 = 0
      @teenagers_amount_2 = 0
      @children_amount_2 = 0
      @total_amount_2 = 0
      @adult_amount_3 = 0
      @teenagers_amount_3 = 0
      @children_amount_3 = 0
      @total_amount_3 = 0
    end
end

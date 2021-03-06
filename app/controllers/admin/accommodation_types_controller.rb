class Admin::AccommodationTypesController < ApplicationController

  include ApplicationHelper

  before_action :set_accommodation_type, only: [:show, :edit, :update]
  before_action :redirect_unless_admin_user

  def index
    @accommodation_types = AccommodationType.all
  end

  def show
    if @accommodation_type.nil?
      flash[:alert] =  t(:accommodation_type_not_found, scope: [:failure]) 
      redirect_to admin_accommodation_types_path  
    end
  end

  def new
    if params[:accommodation_type]
      @accommodation_type = params[:accommodation_type]
    else
      @accommodation_type = AccommodationType.new
    end
  end
 
  def create
    @accommodation_type = AccommodationType.new(accommodation_type_params)
    if @accommodation_type.save
      flash[:notice] = t(:accommodation_type_created, scope: [:success])
      redirect_to [:admin, @accommodation_type]
    else
      flash[:alert] = t(:accommodation_type_create_failed, scope: [:failure])
      render :new
    end  
  end

  def update
    if @accommodation_type.update_attributes(accommodation_type_params)
      flash[:success] = "#{t(:accommodation_type_updated, scope: [:success])} (#{undo_link})"
      redirect_to [:admin, @accommodation_type, @tariff]
    else
      flash[:alert] = t(:accommodation_type_update_failed, scope: [:failure])
      render :edit
    end  
  end

  def edit
    unless (current_user && current_user.admin?)
      flash[:alert] = t(:update_not_allowed, scope: [:failure])
      redirect_to root_path
    end
  end

  def destroy
  end

  private

    def undo_link
      if @accommodation_type.versions.any?
        view_context.link_to(t(:undo, scope: [:actions]), revert_version_path(@accommodation_type.versions.last), method: :post)
      end
    end

    def redo_link
      params[:redo] == "true" ? link = "Undo that plz!" : link = "Redo that plz!"
      view_context.link_to link, undo_path(@accommodation_type.next, redo: !params[:redo]), method: :post
    end

    def set_accommodation_type
      @accommodation_type = AccommodationType.find(params[:id].to_i)
    end

    def accommodation_type_params
      params.require(:accommodation_type).permit(:accom_type, :description, :show, :show_normal_price, :show_in_season_price, :show_promotion)
    end

    def redirect_unless_admin_user
      unless current_user && current_user.admin?
        flash[:alert] = t(:unauthorised_access, scope: [:failure])
        redirect_to root_path
      end
    end

end

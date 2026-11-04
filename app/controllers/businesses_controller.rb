class BusinessesController < ApplicationController
  before_action :set_business, only: %i[show edit update destroy]
  verify_authorized

  def index
    authorize!
    @businesses = Business.alphabetical
  end

  def show
  end

  def new
    authorize!
    @business = Business.new
  end

  def edit
  end

  def create
    authorize!
    @business = Business.new(business_params)

    if @business.save
      redirect_to @business, notice: t(".created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @business.update(business_params)
      redirect_to @business, notice: t(".updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @business.destroy!
    redirect_to businesses_path, notice: t(".destroyed"), status: :see_other
  end

  private

  def set_business
    @business = Business.friendly.find(params[:id])
    authorize! @business
  end

  def business_params = params.expect(business: %i[name description])
end

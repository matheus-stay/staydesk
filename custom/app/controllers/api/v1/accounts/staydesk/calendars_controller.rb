class Api::V1::Accounts::Staydesk::CalendarsController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::Calendar) }
  before_action :fetch_calendar, only: [:show, :update, :destroy]

  def index
    @calendars = Staydesk::Calendar.where(account: Current.account).order(:name)
  end

  def show; end

  def create
    @calendar = Staydesk::Calendar.create!(permitted_payload.merge(account: Current.account))
  end

  def update
    @calendar.update!(permitted_payload)
  end

  def destroy
    @calendar.destroy!
    head :no_content
  end

  private

  def fetch_calendar
    @calendar = Staydesk::Calendar.where(account: Current.account).find(params[:id])
  end

  def permitted_payload
    params.require(:calendar).permit(:name, :timezone, weekly_hours: [:day, :open, :close], holidays: [:date, :name])
  end
end

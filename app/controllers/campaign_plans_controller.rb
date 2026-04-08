class CampaignPlansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_campaign_plan, only: [:update]

  def create
    campaign_plan = current_user.campaign_plans.new(campaign_plan_params)
    campaign_plan.save!

    redirect_to planification_path, notice: "Campaign created."
  end

  def update
    @campaign_plan.update!(campaign_plan_params)

    redirect_to planification_path(anchor: dom_anchor_for(@campaign_plan)), notice: "Planification updated."
  end

  private

  def set_campaign_plan
    @campaign_plan = current_user.campaign_plans.find(params[:id])
  end

  def campaign_plan_params
    attributes = params.require(:campaign_plan).permit(
      :title,
      :start_on,
      :end_on,
      :status,
      :objective,
      :message_angle,
      :expected_outcomes,
      :strategic_alignment,
      :learnings
    )
    attributes[:focus_areas] = sanitize_focus_areas(params.dig(:campaign_plan, :focus_areas_text))
    attributes
  end

  def sanitize_focus_areas(raw_value)
    raw_value.to_s
      .split(/[\n,]/)
      .filter_map { |value| value.to_s.strip.presence }
      .uniq
      .first(12)
  end

  def dom_anchor_for(campaign_plan)
    "campaign-plan-#{campaign_plan.id}"
  end
end

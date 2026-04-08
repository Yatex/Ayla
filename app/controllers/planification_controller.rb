class PlanificationController < ApplicationController
  before_action :authenticate_user!

  def show
    @campaign_plans = current_user.campaign_plans.chronological
    @active_plan = @campaign_plans.find(&:active_now?) || @campaign_plans.find { |plan| plan.status == "active" } || @campaign_plans.find { |plan| plan.status == "draft" }
    @next_plan = @campaign_plans.select { |plan| plan.start_on.present? && plan.start_on > Date.current }.min_by(&:start_on)
    @past_plans = @campaign_plans.select { |plan| %w[completed archived].include?(plan.status) || plan.end_on < Date.current }
    @new_plan = current_user.campaign_plans.new(
      status: "draft",
      start_on: Date.current.beginning_of_month,
      end_on: (Date.current + 3.months).end_of_month
    )
    @plan_metrics = build_plan_metrics(@campaign_plans)
  end

  private

  def build_plan_metrics(plans)
    plans.each_with_object({}) do |plan, memo|
      scope = current_user.content_drafts.where(created_at: plan.start_on.beginning_of_day..plan.end_on.end_of_day)
      memo[plan.id] = {
        draft_count: scope.count,
        pending_count: scope.where(status: "pending_approval").count,
        approved_count: scope.where(status: "approved").count
      }
    end
  end
end

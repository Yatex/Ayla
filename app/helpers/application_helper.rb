module ApplicationHelper
  def ayla_signed_in?
    user_signed_in?
  rescue Devise::MissingWarden
    false
  end

  def marketing_page?
    controller_name == "pages" && action_name == "home" && !ayla_signed_in?
  end

  def ayla_body_class
    ["ayla-body", ("ayla-body--app" if ayla_signed_in?)].compact.join(" ")
  end

  def nav_link_classes(path, starts_with: nil)
    active = current_page?(path)
    active ||= starts_with.present? && request.path.start_with?(starts_with)

    ["nav-link", ("nav-link--active" if active)].compact.join(" ")
  end

  def workspace_task_classes(task)
    tone_class =
      case task.tone
      when "accent"
        "task-card--accent"
      when "warning"
        "task-card--warning"
      when "success"
        "task-card--success"
      else
        "task-card--muted"
      end

    ["task-card", tone_class].join(" ")
  end

  def workspace_task_path(task, telegram_connect_url: nil)
    case task.kind
    when :link_telegram
      telegram_connect_url.presence || settings_path(anchor: "telegram")
    when :finish_onboarding
      onboarding_path
    when :review_queue
      content_drafts_path
    when :capture_new_moment, :restart_rhythm, :maintain_rhythm
      calendar_path
    else
      current_user.telegram_connected? ? calendar_path : (telegram_connect_url.presence || settings_path(anchor: "telegram"))
    end
  end

  def workspace_task_external?(task, telegram_connect_url: nil)
    task.kind == :link_telegram && telegram_connect_url.present? && !current_user.telegram_connected?
  end

  def flash_class(type)
    case type.to_sym
    when :notice
      "flash flash--notice"
    when :alert
      "flash flash--alert"
    else
      "flash"
    end
  end

  def draft_status_badge_class(status)
    tone =
      case status.to_s
      when "pending_approval"
        "status-pill--pending"
      when "approved"
        "status-pill--approved"
      when "rejected"
        "status-pill--rejected"
      else
        "status-pill--draft"
      end

    ["status-pill", tone].join(" ")
  end
end

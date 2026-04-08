module ApplicationHelper
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
      telegram_connect_url.presence || settings_path(anchor: "assistant-channel")
    when :finish_onboarding
      onboarding_path
    when :review_queue
      calendar_path
    when :capture_new_moment, :restart_rhythm, :maintain_rhythm
      calendar_path
    else
      current_user.telegram_connected? ? calendar_path : (telegram_connect_url.presence || settings_path(anchor: "assistant-channel"))
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

  def platform_display_name(platform)
    case platform.to_s.downcase
    when "linkedin"
      "LinkedIn"
    when "x", "twitter"
      "X"
    else
      platform.to_s.titleize
    end
  end

  def platform_short_name(platform)
    case platform.to_s.downcase
    when "instagram"
      "IG"
    when "linkedin"
      "IN"
    when "x", "twitter"
      "X"
    else
      platform.to_s.first(2).upcase
    end
  end

  def platform_description(platform)
    case platform.to_s.downcase
    when "instagram"
      "Visual storytelling, launches, moments, and behind-the-scenes proof."
    when "linkedin"
      "Founder voice, lessons, company momentum, and professional trust."
    when "x", "twitter"
      "Sharp takes, momentum updates, and real-time conversation."
    else
      "Choose where Ayla should shape and organize your publishing plan."
    end
  end

  def platform_badge_class(platform)
    tone =
      case platform.to_s.downcase
      when "instagram"
        "platform-badge--instagram"
      when "linkedin"
        "platform-badge--linkedin"
      when "x", "twitter"
        "platform-badge--x"
      else
        "platform-badge--neutral"
      end

    ["platform-badge", tone].join(" ")
  end

  def assistant_channel_display_name(channel)
    case channel.to_s.downcase
    when "whatsapp"
      "WhatsApp"
    else
      "Telegram"
    end
  end

  def assistant_channel_short_name(channel)
    case channel.to_s.downcase
    when "whatsapp"
      "WA"
    else
      "TG"
    end
  end

  def assistant_channel_description(channel)
    case channel.to_s.downcase
    when "whatsapp"
      "Private, direct conversations for voice notes, quick captures, and follow-ups."
    else
      "Fast prompts, captured moments, and assistant follow-ups directly in chat."
    end
  end

  def assistant_channel_badge_class(channel)
    tone =
      case channel.to_s.downcase
      when "whatsapp"
        "platform-badge--whatsapp"
      else
        "platform-badge--telegram"
      end

    ["platform-badge", tone].join(" ")
  end

  def social_provider_configured?(provider)
    Social::ProviderRegistry.fetch(provider).configured?
  rescue ArgumentError
    false
  end

  def social_provider_supports_text_only_posts?(provider)
    Social::ProviderRegistry.fetch(provider).supports_text_only_posts?
  rescue ArgumentError
    false
  end

  def social_account_status_copy(provider, account)
    return "Connected as #{account.display_handle}" if account&.connected?
    return "App credentials are missing for this provider." unless social_provider_configured?(provider)

    "Ready to connect."
  end

  def social_account_status_tone(provider, account)
    return draft_status_badge_class("approved") if account&.connected?
    return draft_status_badge_class("rejected") unless social_provider_configured?(provider)

    draft_status_badge_class("draft")
  end

  def campaign_plan_status_badge_class(status)
    tone =
      case status.to_s
      when "active"
        "status-pill--approved"
      when "completed"
        "status-pill--draft"
      when "archived"
        "status-pill--rejected"
      else
        "status-pill--pending"
      end

    ["status-pill", tone].join(" ")
  end

  def draft_publishable_to_account?(draft, account)
    return false unless account&.connected?
    return draft.media_url.present? if account.provider == "instagram"

    true
  end

  def draft_publishability_copy(draft, account)
    return "Connect this account in Configuration first." unless account&.connected?
    return "Instagram needs a public media URL on the draft before it can publish." if account.provider == "instagram" && draft.media_url.blank?

    "Ready to publish from this draft."
  end

  def published_post_for(draft, provider)
    draft.published_posts[provider.to_s]
  end

  def calendar_draft_title(draft)
    cleaned = strip_tags(draft.body.to_s).squish
    return "Untitled draft" if cleaned.blank?

    cleaned.split.first(8).join(" ")
  end

  def calendar_draft_excerpt(draft, length: 168)
    truncate(strip_tags(draft.body.to_s).squish, length: length)
  end

  def calendar_draft_status_label(draft)
    case draft.status
    when "pending_approval"
      "Review"
    when "approved"
      "Ready"
    when "rejected"
      "Revise"
    else
      "Draft"
    end
  end

  def calendar_draft_platforms(draft, preferred_platforms: [])
    platforms = draft.platform.to_s.split(",").map { |value| value.to_s.strip.downcase }.reject(&:blank?)
    normalized = platforms & UserPreference::PLATFORMS
    return normalized.uniq if normalized.any?

    preferred_platforms.one? ? preferred_platforms : []
  end

  def calendar_draft_card_class(draft, preferred_platforms: [])
    primary_platform = calendar_draft_platforms(draft, preferred_platforms: preferred_platforms).first
    modifier =
      case primary_platform
      when "instagram"
        "calendar-post-card--instagram"
      when "linkedin"
        "calendar-post-card--linkedin"
      when "x"
        "calendar-post-card--x"
      else
        "calendar-post-card--neutral"
      end

    ["calendar-post-card", modifier].join(" ")
  end
end

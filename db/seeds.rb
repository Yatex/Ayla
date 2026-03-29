if Rails.env.development?
  puts "Seeding development data..."

  user = User.find_or_create_by!(email: "dev@ayla.test") do |u|
    u.name = "Dev User"
    u.password = "password123"
  end

  user.user_profile.update!(
    bio: "Building cool stuff",
    timezone: "America/New_York",
    onboarding_step: "completed",
    onboarded_at: Time.current
  )

  user.user_preference.update!(
    tone: "professional",
    posting_frequency: "daily"
  )

  puts "Created dev user: dev@ayla.test / password123"
end

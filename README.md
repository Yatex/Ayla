# Ayla

**Your AI media manager.** Turn real daily context into social media drafts — right from Telegram.

Ayla is a Telegram-first AI media manager that helps users share what's happening in their day, generates social media drafts, asks for human approval, and posts to connected platforms.

## Stack

- **Ruby on Rails 7.1** — monolith with clean service boundaries
- **PostgreSQL** — primary database
- **Sidekiq + Redis** — background job processing
- **Telegram Bot API** — primary user interface
- **Tailwind CSS** — web UI styling
- **Devise** — authentication
- **AASM** — state machines for models

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Web App                             │
│  (Onboarding, Dashboard, Settings, Draft History)        │
│  Devise auth → Controllers → Views (Tailwind)            │
└─────────────────────────────────────────────────────────┘
                         │
┌─────────────────────────────────────────────────────────┐
│                    Telegram Bot                           │
│  Webhook → ProcessWebhookJob → WebhookProcessor          │
│  → MessageHandler / CallbackHandler                      │
│  → Conversation + Message storage                        │
│  → Draft generation → Approval loop                      │
└─────────────────────────────────────────────────────────┘
                         │
┌─────────────────────────────────────────────────────────┐
│                   Service Layer                           │
│  Telegram::  (BotClient, WebhookProcessor, Handlers)     │
│  Conversations::  (Manager)                              │
│  Drafts::  (Generator, ApprovalHandler)                  │
│  Ai::  (Client, PromptBuilder)                           │
└─────────────────────────────────────────────────────────┘
                         │
┌─────────────────────────────────────────────────────────┐
│                   Background Jobs                         │
│  Telegram::ProcessWebhookJob                             │
│  Telegram::SendMessageJob                                │
│  Drafts::GenerateDraftJob                                │
└─────────────────────────────────────────────────────────┘
```

## Data Model

```
User (Devise)
 ├── has_one  UserProfile        (bio, timezone, onboarding state)
 ├── has_one  UserPreference     (tone, frequency, content prefs)
 ├── has_one  TelegramConnection (telegram IDs, conversation state machine)
 ├── has_many Conversations      (grouped message threads)
 │    └── has_many Messages      (role: user/assistant/system)
 └── has_many ContentDrafts      (body, status: draft→pending_approval→approved→rejected)
```

## Telegram Message Flow

1. User sends message to Ayla bot on Telegram
2. Telegram POSTs webhook → `Telegram::WebhooksController#create`
3. Enqueues `Telegram::ProcessWebhookJob` (fast 200 OK response)
4. Job → `Telegram::WebhookProcessor` identifies user via `TelegramConnection`
5. Routes to `MessageHandler` (text) or `CallbackHandler` (button taps)
6. Message stored in `Conversation` → `Message`
7. After enough context → suggests draft generation
8. `Drafts::GenerateDraftJob` → AI generates draft → `ContentDraft` (pending_approval)
9. Draft sent to user with Approve/Reject buttons
10. User taps → `CallbackHandler` → `Drafts::ApprovalHandler`

## Setup

```bash
# Install dependencies
bundle install

# Create and migrate database
rails db:create db:migrate

# Seed dev user
rails db:seed

# Copy environment file
cp .env.example .env
# Fill in TELEGRAM_BOT_TOKEN, TELEGRAM_BOT_USERNAME, OPENAI_API_KEY
# If you run multiple apps locally, give Ayla its own Redis DB via SIDEKIQ_REDIS_URL

# Start all services
bin/dev
```

**Dev credentials:** `dev@ayla.test` / `password123`

## Key Directories

```
app/
├── controllers/
│   ├── telegram/webhooks_controller.rb   # Webhook endpoint
│   ├── dashboard_controller.rb           # Main dashboard
│   ├── onboarding_controller.rb          # Onboarding wizard
│   ├── settings_controller.rb            # User settings
│   └── content_drafts_controller.rb      # Draft history
├── models/
│   ├── user.rb                           # Core user (Devise)
│   ├── user_profile.rb                   # Extended profile
│   ├── user_preference.rb                # Content preferences
│   ├── telegram_connection.rb            # Telegram link + state
│   ├── conversation.rb                   # Message thread
│   ├── message.rb                        # Individual message
│   └── content_draft.rb                  # Generated draft
├── services/
│   ├── telegram/
│   │   ├── bot_client.rb                 # Telegram API wrapper
│   │   ├── webhook_processor.rb          # Parse & route webhooks
│   │   ├── message_handler.rb            # Handle text messages
│   │   └── callback_handler.rb           # Handle button callbacks
│   ├── conversations/
│   │   └── manager.rb                    # Conversation lifecycle
│   ├── drafts/
│   │   ├── generator.rb                  # AI draft generation
│   │   └── approval_handler.rb           # Approve/reject flow
│   └── ai/
│       ├── client.rb                     # LLM API client
│       └── prompt_builder.rb             # Prompt construction
├── jobs/
│   ├── telegram/
│   │   ├── process_webhook_job.rb        # Async webhook processing
│   │   └── send_message_job.rb           # Send Telegram messages
│   └── drafts/
│       └── generate_draft_job.rb         # Generate draft async
└── views/                                # Tailwind-styled ERB views
```

## Web Routes

| Route | Description |
|---|---|
| `POST /telegram/webhook/:token` | Telegram webhook endpoint |
| `GET /` | Landing page |
| `GET /dashboard` | User dashboard |
| `GET /onboarding` | Onboarding wizard |
| `GET /settings` | Profile & preferences |
| `GET /content_drafts` | Draft history |
| `GET /content_drafts/:id` | Single draft view |
| `GET /sidekiq` | Sidekiq monitoring |

## Next Steps

- [ ] Set up Telegram bot and configure webhook
- [ ] Connect OpenAI API key for real draft generation
- [ ] Add social platform publishing (Twitter/X, LinkedIn, etc.)
- [ ] Add RSpec tests for service objects
- [ ] Deploy to production

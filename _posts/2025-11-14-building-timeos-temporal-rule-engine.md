---
layout: default
title: "Building TimeOS: A Temporal Rule Engine for Elixir That Actually Makes Sense"
date: 2025-11-14
---

# Building TimeOS: A Temporal Rule Engine for Elixir That Actually Makes Sense

*How we built a production-ready job scheduling system that doesn't make you want to pull your hair out*

---

## The Problem: Why Another Job Scheduler?

Let's be honest. Job scheduling in Elixir can be... frustrating. You have options, sure. But they're either too simple (can't handle complex rules), too complex (requires a PhD to configure), or they make you write code that looks like it came from the 90s.

We wanted something different. Something that:

- **Reads like English** - Your rules should make sense at 2 AM when you're debugging

- **Handles the real world** - Timezones, rate limits, dependencies, retries

- **Doesn't break** - Graceful shutdowns, health checks, observability

- **Looks good** - Because who doesn't love a nice dashboard?

So we built **TimeOS** - a temporal rule engine that actually makes sense.

---

## What We Built: The TimeOS Story

### The Vision

TimeOS is a temporal rule engine that lets you define **what** should happen **when** in a declarative, readable way. Think of it as cron on steroids, but actually usable.

### The Journey

We started with a simple idea: "What if scheduling jobs was as easy as writing a rule?"

```elixir
on_event :user_signup, offset: days(2) do
  perform :send_welcome_email
end
```

That's it. That's the whole rule. When a user signs up, wait 2 days, then send them a welcome email. No timers. No GenServers. No headaches.

But then we thought: "What if we need more?"

So we added:

- **Cron expressions** for complex schedules

- **Day-of-week helpers** because who remembers cron syntax?

- **Timezone support** because the world is round

- **Rate limiting** because APIs have feelings too

- **Job dependencies** because sometimes job A needs to finish before job B

- **Dead letter queues** because failures happen

- **A beautiful web UI** because we're visual creatures

And here we are.

---

## How It Works: Under the Hood

### The DSL: Writing Rules That Make Sense

TimeOS uses a DSL (Domain-Specific Language) that reads like English. Here's how you define rules:

```elixir
defmodule MyApp.Rules do
  use TimeOS.DSL.RuleSet

  # Event-driven: Trigger after an event occurs
  on_event :user_signup, offset: hours(1) do
    perform :send_onboarding_email
  end

  # Periodic: Run every X minutes/hours/days
  every minutes(30) do
    perform :check_system_health
  end

  # Cron: Full cron expression support
  cron "0 9 * * 1", timezone: "America/New_York" do
    perform :monday_morning_report
  end

  # Day-of-week helpers: Because cron is hard
  every_monday at: "09:00", timezone: "America/New_York" do
    perform :send_weekly_newsletter
  end

  # Conditional: Only trigger when conditions are met
  on_event :payment_received, offset: minutes(15), when: fn payload ->
    payload["amount"] > 1000
  end do
    perform :send_premium_receipt
  end
end
```

See? It reads like English. No magic. No confusion. Just rules.

### The Architecture: Simple, But Powerful

TimeOS is built on a few key components:

1. **RuleRegistry** - Stores and manages your rules

2. **EventReceiver** - Receives events and forwards them to the evaluator

3. **Evaluator** - Matches events against rules and creates jobs

4. **Scheduler** - Polls for due jobs and spawns workers

5. **JobWorker** - Executes jobs with retry logic

6. **RateLimiter** - Enforces rate limits (token bucket algorithm)

7. **Web UI** - Beautiful dashboard for monitoring

### The Flow: From Event to Execution

Here's what happens when you emit an event:

```elixir
# 1. You emit an event
TimeOS.emit(:user_signup, %{"user_id" => "123"})

# 2. EventReceiver receives it
# 3. Evaluator matches it against rules
# 4. Jobs are created and scheduled
# 5. Scheduler picks up due jobs
# 6. JobWorker executes them
# 7. Results are tracked
```

Simple, right? But powerful enough to handle complex scenarios.

---

## Real-World Examples: Because Code Speaks Louder Than Words

### E-commerce: Order Processing

```elixir
defmodule Order.Rules do
  use TimeOS.DSL.RuleSet

  # Process payment 15 minutes after order
  on_event :order_placed, offset: minutes(15) do
    perform :process_payment
  end

  # Send notification if payment fails
  on_event :payment_failed, offset: hours(1) do
    perform :send_payment_failure_notification
  end

  # Follow up 7 days after shipping
  on_event :order_shipped, offset: days(7) do
    perform :send_delivery_confirmation
  end

  # Daily inventory check
  cron "0 2 * * *", timezone: "UTC" do
    perform :check_inventory_levels
  end
end
```

### User Engagement: Onboarding Flow

```elixir
defmodule Engagement.Rules do
  use TimeOS.DSL.RuleSet

  # Immediate welcome
  on_event :user_signup, offset: minutes(5) do
    perform :send_welcome_email
  end

  # Check activation after 3 days
  on_event :user_signup, offset: days(3) do
    perform :check_activation
  end

  # Re-engagement for inactive users
  on_event :user_inactive, offset: days(7) do
    perform :send_reactivation_email
  end

  # Weekly engagement analysis
  every_monday at: "10:00", timezone: "UTC" do
    perform :daily_engagement_analysis
  end
end
```

### System Maintenance: Keeping Things Running

```elixir
defmodule Maintenance.Rules do
  use TimeOS.DSL.RuleSet

  # Health checks every hour
  every hours(1) do
    perform :check_system_health
  end

  # Daily backups
  every days(1), timezone: "UTC" do
    perform :backup_database
  end

  # Weekly maintenance on Sundays
  every_sunday at: "02:00", timezone: "America/New_York" do
    perform :weekly_maintenance
  end

  # Monthly cleanup
  cron "0 0 1 * *" do
    perform :monthly_cleanup
  end
end
```

---

## Advanced Features: The Good Stuff

### Job Prioritization: What Matters Most

Sometimes, not all jobs are created equal. TimeOS lets you set priorities:

```elixir
# High priority jobs run first
on_event :critical_alert, offset: seconds(0) do
  perform :handle_critical_alert
end

# Then update the rule with priority
rule = TimeOS.list_rules() |> Enum.find(&(&1.name =~ "critical_alert"))
TimeOS.update_rule(rule.id, %{priority: 100})
```

Higher priority = runs first. Simple.

### Rate Limiting: Be Nice to APIs

APIs have rate limits. TimeOS respects them:

```elixir
# Limit to 10 executions per minute
rule = TimeOS.list_rules() |> Enum.find(&(&1.name =~ "send_email"))
TimeOS.update_rule(rule.id, %{rate_limit_per_minute: 10})
```

TimeOS uses a token bucket algorithm to enforce rate limits. Jobs that exceed the limit are automatically deferred.

### Timezone Support: The World is Round

Scheduling jobs in different timezones? TimeOS handles it:

```elixir
# Monday morning report in New York time
every_monday at: "09:00", timezone: "America/New_York" do
  perform :morning_report
end

# Lunch reminder in London time
cron "0 12 * * *", timezone: "Europe/London" do
  perform :lunch_reminder
end
```

TimeOS automatically converts everything to UTC internally, so you don't have to think about it.

### Dead Letter Queue: When Things Go Wrong

Jobs fail. It happens. TimeOS has a dead letter queue for permanently failed jobs:

```elixir
# List dead letter jobs
dead_jobs = TimeOS.list_dead_letter_jobs()

# Inspect and retry
for job <- dead_jobs do
  IO.inspect(job.last_error)
  TimeOS.retry_dead_letter_job(job.id)
end
```

### Job Dependencies: When Order Matters

Sometimes job B needs job A to finish first:

```elixir
# Job A: Process data
job_a = create_job(:process_data)

# Job B: Send notification (depends on A)
job_b = create_job(:send_notification, depends_on_job_id: job_a.id)
```

TimeOS automatically waits for dependencies before executing jobs.

---

## The Web UI: Because We're Visual Creatures

Let's be honest - command line is great, but sometimes you want to **see** what's happening. That's why we built a beautiful web UI.

### Real-Time Job Monitoring

The dashboard shows you:

- **Pending jobs** - Waiting to run

- **Running jobs** - Currently executing

- **Completed jobs** - Successfully finished

- **Failed jobs** - Need attention

- **Dead letter jobs** - Permanently failed

### System Health

Monitor your system health in real-time:

- Database connectivity

- Component status

- Metrics overview

- System alerts

### Metrics at a Glance

See your system metrics:

- Total jobs

- Success rate

- Average execution time

- Rate limit status

---

## Why TimeOS is Good: The Real Talk

### 1. It Actually Makes Sense

Most job schedulers require you to think in their terms. TimeOS thinks in **your** terms. Want something to happen after an event? Say so. Want it to run every Monday? Say so. No translation needed.

### 2. Production-Ready Features

TimeOS isn't a toy. It has:

- **Graceful shutdown** - Waits for in-flight jobs

- **Health checks** - Know when something's wrong

- **Telemetry** - Built-in observability

- **Retry logic** - Exponential backoff

- **Idempotency** - Prevent duplicate jobs

- **Data cleanup** - Prevents database bloat

### 3. Developer Experience

Writing rules is fun. Seriously. The DSL is intuitive, the error messages are helpful, and the documentation is comprehensive.

```elixir
# This is all you need
on_event :user_signup, offset: days(2) do
  perform :send_welcome_email
end
```

No boilerplate. No magic. Just rules.

### 4. It Scales

TimeOS handles:

- Thousands of jobs

- Complex dependencies

- Rate limits

- Multiple timezones

- High throughput

And it does it all without breaking a sweat.

### 5. The Web UI is Actually Good

Most job schedulers have UIs that look like they were designed in 1995. TimeOS has a modern, beautiful dashboard that you'll actually want to use.

---

## The Technical Deep Dive: How We Built It

### The DSL: Making Rules Readable

The DSL is built using Elixir's macro system. When you write:

```elixir
on_event :user_signup, offset: days(2) do
  perform :send_welcome_email
end
```

TimeOS compiles it into a structured format that can be stored, evaluated, and executed. The magic is in making it feel natural while being powerful.

### The Evaluator: Matching Events to Rules

When an event is emitted, the Evaluator:

1. Loads all enabled rules

2. Matches the event type

3. Evaluates `when` clauses (if any)

4. Calculates execution times (with timezone support)

5. Creates scheduled jobs

All of this happens asynchronously, so your application doesn't block.

### The Scheduler: Picking Up Due Jobs

The Scheduler polls for due jobs every second (configurable). It:

1. Queries for pending jobs that are due

2. Checks dependencies

3. Verifies rate limits

4. Spawns workers

Jobs are ordered by priority, so important jobs run first.

### The JobWorker: Executing with Grace

JobWorkers execute jobs with:

- **Retry logic** - Exponential backoff

- **Status tracking** - Know what's happening

- **Error handling** - Graceful failures

- **Graceful shutdown** - Finishes before stopping

---

## Performance: Because Speed Matters

TimeOS is fast. Here's why:

- **Efficient queries** - Indexed database queries

- **Connection pooling** - Reuses database connections

- **Async processing** - Doesn't block your app

- **Smart polling** - Only queries when needed

- **Optimized scheduling** - Batch operations where possible

We've tested it with:

- 10,000+ jobs

- 100+ rules

- Multiple timezones

- Complex dependencies

And it handles it all smoothly.

---

## Getting Started: Your First Rule

Ready to try TimeOS? Here's how:

### 1. Add to Your Project

```elixir
# mix.exs
def deps do
  [
    {:timeos, "~> 0.1.0"}
  ]
end
```

### 2. Define Your Rules

```elixir
defmodule MyApp.Rules do
  use TimeOS.DSL.RuleSet

  on_event :user_signup, offset: hours(1) do
    perform :send_welcome_email
  end
end
```

### 3. Register Your Rules

```elixir
TimeOS.load_rules_from_module(MyApp.Rules)
```

### 4. Create a Performer

```elixir
defmodule MyApp.Performer do
  def perform(:send_welcome_email, payload) do
    user_id = payload["user_id"]
    Email.send_welcome(user_id)
    :ok
  end
end
```

### 5. Register the Performer

```elixir
TimeOS.register_performer(MyApp.Performer)
```

### 6. Emit Events

```elixir
TimeOS.emit(:user_signup, %{"user_id" => "123"})
```

That's it! Your job is scheduled and will execute automatically.

---

## The Road Ahead: What's Next?

TimeOS is already powerful, but we're not done. Here's what's coming:

- **More scheduling options** - More flexibility

- **Better observability** - More metrics

- **Enhanced UI** - More features

- **Performance improvements** - Always faster

- **Community features** - Built by you

---

## Conclusion: Why TimeOS Matters

Building TimeOS taught us a lot. We learned that:

- **Simplicity wins** - Complex solutions create complex problems

- **Developer experience matters** - If it's not fun to use, people won't use it

- **Real-world features are essential** - Timezones, rate limits, dependencies

- **Visual feedback is important** - Dashboards aren't just nice-to-have

TimeOS isn't just another job scheduler. It's a **temporal rule engine** that makes scheduling jobs actually enjoyable.

---

## Try It Yourself

Ready to give TimeOS a try?

```bash
# Add to your project
mix deps.add timeos

# Or check it out on GitHub
# https://github.com/ijunaid8989/timeOS

# Or install from Hex
# https://hex.pm/packages/timeos
```

We'd love to hear what you think! Open an issue, submit a PR, or just say hi.

---

*TimeOS is open source and available on [GitHub](https://github.com/ijunaid8989/timeOS) and [Hex](https://hex.pm/packages/timeos). Built with ❤️ by developers who were tired of complex job schedulers.*


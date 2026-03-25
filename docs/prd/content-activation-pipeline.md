# PRD: Content Activation Pipeline

> **Priority**: P1 — High
> **Publisher Prefix**: `cap_`
> **Solution Name**: ContentActivationPipeline

## Overview

Build an AI-augmented content activation pipeline for the **Copilot Studio Kit (CSK)** team that transforms product updates, feature releases, and team insights into multi-platform social media content. When the team ships a new CSK release, records a voice note about a feature, or forwards an interesting customer win — the pipeline automatically generates LinkedIn posts, X/Twitter threads, blog drafts, email newsletters, and Teams announcements optimized for each platform.

The system captures ideas from a Microsoft Teams channel, generates platform-optimized content using Azure OpenAI (tuned to CSK brand voice), routes through a human approval workflow via Adaptive Cards, and publishes to configured social channels automatically.

Built entirely on Microsoft first-party tools (Power Platform, Azure AI, Teams, SharePoint) — dogfooding the same stack CSK helps customers adopt.

## User Stories

### CSK Team Member (Content Creator)
- As a CSK team member, I want to post a quick note about a feature release in a Teams channel (text, voice note, or forwarded message), so that it automatically becomes multi-platform social content for our CSK community
- As a CSK team member, I want AI to generate platform-optimized versions of my update (LinkedIn post, X thread, blog draft, email blurb, Teams announcement), using our CSK brand voice and messaging guidelines
- As a CSK team member, I want AI-generated images that match Microsoft brand guidelines (blue #0078D4, clean tech illustrations, no logos), so that every post has a professional visual
- As a CSK team member, I want to see a dashboard of all content in various pipeline stages, so that I can track what's pending, approved, and published across platforms

### Content Approver (CSK Lead / PM)
- As a CSK lead, I want to review generated content via an Adaptive Card in Teams, so that I can approve, request edits, or reject without leaving Teams
- As a CSK lead, I want to see the original idea alongside the generated content, so that I can verify accuracy, tone, and alignment with our release messaging
- As a CSK lead, I want approval requests to expire after 48 hours with a 24-hour reminder, so that content doesn't get stuck

### Platform Admin
- As a platform admin, I want to configure which social channels are enabled and their posting parameters, so that I can control where CSK content gets published
- As a platform admin, I want to see publishing logs with success/failure details, so that I can troubleshoot failed posts
- As a platform admin, I want rate limit management and retry logic, so that publishing doesn't fail due to API throttling

## Data Model

### Tables

#### `cap_ContentIdea` — Content idea submissions
| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `cap_name` | Text (200) | Yes | Idea title (auto-generated or user-provided) |
| `cap_sourcemessage` | Multiline Text (10000) | No | Original message content |
| `cap_sourcetype` | Choice | No | Voice / Text / Forward / File / Manual |
| `cap_transcript` | Multiline Text (10000) | No | Transcribed text (for voice inputs) |
| `cap_status` | Choice | Yes | Draft → Transcribing → Transcribed → Generating → Generated → InReview → Approved → Publishing → Published → Rejected → Failed |
| `cap_contentgroupid` | Text (100) | No | Groups related content pieces together |
| `cap_targetplatforms` | Text (500) | No | Comma-separated platform list |
| `cap_generateimages` | Boolean | No | Whether to generate images for this idea |
| `cap_submittedon` | DateTime | No | When the idea was submitted |
| `cap_teamsmessageid` | Text (200) | No | Source Teams message ID for traceability |
| `cap_voicerecordingurl` | URL | No | Link to archived voice recording |

#### `cap_ContentPiece` — Platform-specific generated content
| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `cap_name` | Text (200) | Yes | Piece title |
| `cap_contentideaid` | Lookup → cap_ContentIdea | Yes | Parent idea |
| `cap_platform` | Choice | Yes | LinkedIn / Twitter / Blog / Email / Teams |
| `cap_generatedcontent` | Multiline Text (50000) | No | The generated text content |
| `cap_generatedcontentjson` | Multiline Text (100000) | No | Structured JSON output from AI |
| `cap_status` | Choice | Yes | PendingGeneration → Generated → InReview → Approved → Scheduled → Publishing → Published → Rejected → Failed → EditRequested |
| `cap_scheduleddate` | DateTime | No | When to publish |
| `cap_publisheddate` | DateTime | No | When actually published |
| `cap_approvalstatus` | Choice | No | Pending / Approved / Rejected / EditRequested |
| `cap_approvercomments` | Multiline Text (5000) | No | Reviewer feedback |
| `cap_approvedby` | Lookup → User | No | Who approved |
| `cap_errordetails` | Multiline Text (5000) | No | Error info if failed |
| `cap_posturl` | URL | No | Link to the published post |
| `cap_hashtags` | Text (500) | No | Generated hashtags |
| `cap_charactercount` | Integer | No | Character count of generated content |
| `cap_editedcontent` | Multiline Text (50000) | No | Human-edited version |

#### `cap_MediaAsset` — Generated images and media files
| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `cap_name` | Text (200) | Yes | Asset name |
| `cap_contentideaid` | Lookup → cap_ContentIdea | No | Parent idea |
| `cap_contentpieceid` | Lookup → cap_ContentPiece | No | Parent content piece |
| `cap_mediatype` | Choice | No | GeneratedImage / VoiceRecording / BlogDraft / Video / Template / Thumbnail |
| `cap_fileurl` | URL | No | URL to the media file |
| `cap_alttext` | Text (1000) | No | Accessibility alt text |
| `cap_generationprompt` | Multiline Text (5000) | No | The DALL-E prompt used |
| `cap_platform` | Choice | No | Which platform this image is sized for |
| `cap_width` | Integer | No | Image width in pixels |
| `cap_height` | Integer | No | Image height in pixels |

#### `cap_PlatformConfig` — Platform publishing configuration
| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `cap_name` | Text (100) | Yes | Platform display name |
| `cap_platformkey` | Text (50) | Yes | Machine key (linkedin, twitter, blog, email, teams) |
| `cap_enabled` | Boolean | Yes | Whether this platform is active |
| `cap_connectorname` | Text (200) | No | Power Automate connector name |
| `cap_prompttemplate` | Multiline Text (10000) | No | AI prompt template for this platform |
| `cap_maxcontentlength` | Integer | No | Max character/word count |
| `cap_imagewidth` | Integer | No | Default image width |
| `cap_imageheight` | Integer | No | Default image height |
| `cap_maxhashtags` | Integer | No | Max number of hashtags |
| `cap_hashtagstrategy` | Choice | No | Append / Inline / None |
| `cap_includeimage` | Boolean | No | Whether to generate images |
| `cap_settingsjson` | Multiline Text (10000) | No | Platform-specific JSON config |
| `cap_iconurl` | URL | No | Platform icon |
| `cap_sortorder` | Integer | No | Display order |

#### `cap_PublishLog` — Publishing attempt audit trail
| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `cap_name` | Text (200) | Yes | Log entry name |
| `cap_contentpieceid` | Lookup → cap_ContentPiece | Yes | Content piece that was published |
| `cap_platform` | Choice | No | Target platform |
| `cap_action` | Choice | No | Publish / Retry / Fail / ManualPublish / Regenerate / Cancel |
| `cap_success` | Boolean | No | Whether the publish succeeded |
| `cap_httpstatuscode` | Integer | No | HTTP response code |
| `cap_responsedetails` | Multiline Text (10000) | No | API response body |
| `cap_attempteddate` | DateTime | No | When the attempt was made |
| `cap_attemptnumber` | Integer | No | Retry attempt number |
| `cap_posturl` | URL | No | URL of the published post |
| `cap_flowrunid` | Text (200) | No | Power Automate flow run ID |

### Relationships
- `cap_ContentPiece` → `cap_ContentIdea` (Many-to-One, required)
- `cap_MediaAsset` → `cap_ContentIdea` (Many-to-One, optional)
- `cap_MediaAsset` → `cap_ContentPiece` (Many-to-One, optional)
- `cap_PublishLog` → `cap_ContentPiece` (Many-to-One, required)

## Architecture — 6-Layer Pipeline

```
Layer 1: CAPTURE         Teams channel → new message → trigger flow
Layer 2: TRANSCRIBE      Voice → Azure AI Speech → text transcript
Layer 3: GENERATE         Text → Azure OpenAI (GPT-4o) → platform-specific content
                          Text → Azure OpenAI (DALL-E 3) → brand-consistent images
Layer 4: REVIEW           Adaptive Card approval in Teams → approve/edit/reject
Layer 5: PUBLISH          Scheduled Power Automate flows → platform connectors
Layer 6: MONITOR          Power BI dashboard → pipeline metrics + engagement analytics
```

## App Screens (React Code App — Fluent UI v9)

The management UI is a Power Apps Code App (React SPA hosted on Power Platform):

1. **Dashboard** — Pipeline stats (total ideas, pending review, approved, published, failed, this week), recent activity feed
2. **Ideas** — Searchable/filterable list of all content ideas with status badges and source type icons
3. **Review** — Approval queue showing content pieces pending review, with inline approve/reject/edit actions
4. **Schedule** — Calendar-style view of scheduled and published content across platforms
5. **Platforms** — Configuration cards for each platform (enable/disable, connector settings, prompt templates)
6. **History** — Published content log with links to live posts, success/failure status, and engagement metrics

## Automations (5 Cloud Flows)

### Flow 01: Capture & Transcribe
- **Trigger**: When a new message is posted in "Content Ideas" Teams channel
- **Actions**: Detect source type → extract audio if voice → Azure AI Speech transcription → create cap_ContentIdea record → archive media to SharePoint
- **Error handling**: If transcription fails, set status to Failed with error details

### Flow 02: Generate Content
- **Trigger**: When cap_ContentIdea status changes to "Transcribed" or "Text Input"
- **Actions**: For each enabled platform → call Azure OpenAI with platform-specific prompt → create cap_ContentPiece records → update idea status to "Generated"
- **Parallelism**: All platform generations run in parallel branches

### Flow 03: Generate Images
- **Trigger**: When cap_ContentIdea status changes to "Generated" AND generateimages = true
- **Actions**: For each content piece → generate DALL-E prompt from content → call DALL-E 3 → save image to SharePoint → create cap_MediaAsset record → update idea status to "InReview"

### Flow 04: Approval Workflow
- **Trigger**: When cap_ContentIdea status changes to "InReview"
- **Actions**: Build Adaptive Card with all generated content + images → post to "Content Approvals" Teams channel → wait for response → update piece statuses based on approval action
- **SLA**: 48-hour expiry with 24-hour reminder

### Flow 05: Publish Content
- **Trigger**: Recurrence (every 15 minutes)
- **Actions**: Query approved pieces where ScheduledDate ≤ now → post to each platform via connectors → create cap_PublishLog records → update status to Published or Failed
- **Retry**: 3 attempts with exponential backoff, then mark Failed

## Platform Connectors

| Platform | Connector | Image Size | Max Length | Hashtag Strategy |
|----------|-----------|------------|------------|------------------|
| LinkedIn | LinkedIn V2 (built-in) | 1200×628 | 3,000 chars | Append (5 max) |
| X/Twitter | X connector (BYOA) | 1200×675 | 280 chars/tweet, 4-8 tweet threads | Inline (3 max) |
| Blog | HTTP connector | N/A | 800-1,500 words | None |
| Email | Office 365 Outlook | N/A | 200 words | None |
| Teams | Teams connector | N/A | 500 chars | None |

## AI Prompt Templates

Six prompt templates are included in `src/prompts/`:
- `linkedin-post.md` — Professional thought leadership posts
- `x-twitter-thread.md` — Punchy threads (≤280 char per tweet)
- `blog-draft.md` — Long-form Tech Community/learn.microsoft.com posts
- `email-newsletter.md` — Newsletter blurbs with CTA
- `teams-announcement.md` — Internal field enablement posts
- `image-prompt-generator.md` — DALL-E 3 prompt optimization

All prompts output structured JSON and are tuned for Copilot Studio Kit brand voice.

## Environment Variables

| Variable | Type | Description |
|----------|------|-------------|
| `cap_AzureOpenAIEndpoint` | Text | Azure OpenAI resource endpoint URL |
| `cap_AzureOpenAIGPTDeployment` | Text | GPT model deployment name (default: gpt-4o) |
| `cap_AzureOpenAIDALLEDeployment` | Text | DALL-E model deployment name (default: dall-e-3) |
| `cap_AzureOpenAIApiVersion` | Text | API version (default: 2024-10-21) |
| `cap_AzureSpeechEndpoint` | Text | Azure AI Speech endpoint URL |
| `cap_AzureSpeechRegion` | Text | Azure AI Speech region (default: eastus) |
| `cap_SharePointSiteUrl` | Text | SharePoint site URL for content storage |
| `cap_ContentPipelineListName` | Text | SharePoint list name (default: Content Pipeline) |
| `cap_TeamsTeamId` | Text | Teams team ID for content channels |
| `cap_ContentIdeasChannelId` | Text | Content Ideas channel ID |
| `cap_ApprovalsChannelId` | Text | Content Approvals channel ID |
| `cap_DefaultScheduleDelayHours` | Text | Hours to delay publish after approval (default: 1) |
| `cap_EnabledPlatforms` | Text | Comma-separated enabled platforms (default: LinkedIn,Teams,Email) |

## Connection References

| Connector | Connection Reference Name |
|-----------|--------------------------|
| Microsoft Teams | `cap_sharedteams` |
| SharePoint | `cap_sharedSharePoint` |
| Office 365 Outlook | `cap_sharedOffice365` |
| LinkedIn V2 | `cap_sharedLinkedInV2` |
| HTTP with Azure AD | `cap_sharedHttpWithAzureAD` |

## Copilot Studio Agent

- **Content Pipeline Helper** — conversational agent that answers:
  - "What's the status of my latest idea?"
  - "How many posts are pending review?"
  - "Show me this week's published content"
  - "Submit a new content idea: [text]"
  - Uses Dataverse queries to retrieve pipeline data

## Power BI Dashboard

- Pipeline throughput funnel (Ideas → Generated → Approved → Published)
- Content velocity (ideas/week, posts/week trend line)
- Approval turnaround time (avg hours from generation to approval)
- Platform distribution (posts per platform, pie chart)
- Failure rate (rejected + failed / total, with error category breakdown)
- KPIs: Total ideas, Approval rate, Avg time-to-publish, Active platforms

## Azure Resource Requirements

- **Azure OpenAI**: GPT-4o deployment + DALL-E 3 deployment
- **Azure AI Speech**: Speech-to-Text REST API v3.2
- Both should use managed identity or service principal (no API keys in flows)

## Acceptance Criteria

- [ ] Content creators can submit ideas by posting in a Teams channel (text, voice, or forward)
- [ ] Voice messages are automatically transcribed via Azure AI Speech
- [ ] AI generates platform-optimized content for all enabled platforms
- [ ] AI generates brand-consistent images via DALL-E 3
- [ ] Content appears in the React Code App management dashboard
- [ ] Approvers receive Adaptive Cards in Teams with approve/edit/reject actions
- [ ] Approved content publishes automatically on the scheduled date/time
- [ ] Failed publishes retry 3x with exponential backoff
- [ ] Publishing logs capture every attempt with HTTP status codes
- [ ] Power BI dashboard shows real-time pipeline metrics
- [ ] Platform configurations are editable (enable/disable, image sizes, hashtag strategy)
- [ ] Copilot agent can answer pipeline status queries
- [ ] All AI calls use managed identity/service principal (no API keys in flows)
- [ ] Solution imports cleanly via PAC CLI pipeline

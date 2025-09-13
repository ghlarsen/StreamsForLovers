# Interactive AI Music Streaming Project Plan

## 🎯 Project Overview
Create a 24/7 interactive AI music streaming system where viewers can influence music generation through chat commands, votes, and real-time interaction. Think "Lofi Girl" but with AI-generated music that responds to audience input.

## 💰 Cost Structure

### **Infrastructure**
- **VPS**: Contabo €4.02/month (3 vCPU, 8GB RAM, 32TB traffic)

### **AI Generation APIs**
- **Music**: Suno.ai via third-party ~$0.01/song (~$3.60/month for 12 songs/day)
- **Video Backgrounds**: Adobe Firefly Standard $9.99/month (2,000 credits ~20 videos)

### **Total Monthly Cost**
- **Budget Tier**: ~$18/month (€4.02 + $3.60 + $9.99)
- **Growth Tier**: ~$25/month (add dual server failover €4.02 extra)

### **API Alternatives by Budget**

#### **Music Generation**
| Provider | Cost | Quality | Notes |
|----------|------|---------|-------|
| Suno.ai (3rd party) | $0.01/song | Excellent | **Recommended** |
| Suno.ai (official) | $0.04/song | Excellent | 4x more expensive |
| AIVA | $11-33/month | Good | Subscription model |
| Stable Audio | $12/month | Good | 500 tracks/month |
| MusicGen | Free | Good | Self-hosted, needs GPU |

#### **Animated Backgrounds**
| Provider | Cost | Quality | Best For |
|----------|------|---------|----------|
| Adobe Firefly | $9.99/month | High | **Abstract backgrounds** |
| Kling AI | $6.99/month | High | Cinematic quality |
| Runware.ai | Pay-per-use | Medium | **Budget/sporadic use** |
| Google Veo 3 | $19.99/month | Premium | High-end production |
| Magic Hour | Free tier + paid | Medium | Multi-tool platform |

## 📋 Implementation Plan

### Phase 1: Core Infrastructure Setup (Week 1-2)
- [x] ~~Purchase Contabo VPS~~ (€4.02/month - 3 vCPU, 8GB RAM, 32TB traffic)
- [x] ~~Install Ubuntu Server~~ with security hardening (firewall, SSH keys)
- [ ] Set up OBS Studio headless with virtual display for 1080p streaming
- [ ] Configure RTMP streaming to YouTube Live with optimal settings
- [ ] Integrate Suno.ai API (third-party provider ~$0.01/song for cost efficiency)

### Phase 2: Interactive Music Generation System (Week 2-3)
- [ ] Build chat monitoring bot to capture YouTube Live chat commands
- [ ] Create prompt generation system that converts user requests to Suno prompts
- [ ] Implement music queue management (user requests + automated fallbacks)
- [ ] Add voting/polling system for community-driven track selection
- [ ] Test music generation pipeline with various user input scenarios

### Phase 3: Visual Content & User Interface (Week 3-4)
- [ ] Create animated backgrounds that match generated music moods
- [ ] Implement OBS scene switching based on music themes
- [ ] Add text overlays showing current track info, user requests, generation status
- [ ] Build simple web dashboard for stream monitoring and manual control
- [ ] Test visual synchronization with music transitions

### Phase 4: Advanced Interactivity (Week 4-5)
- [ ] Add real-time chat integration (!generate, !request, !vote commands)
- [ ] Implement weather/time-based automatic generation
- [ ] Create rating system for community feedback on tracks
- [ ] Add themed streaming hours (Viewer Choice vs AI Surprise)
- [ ] Build request queue visualization for transparency

### Phase 5: Launch & Optimization (Week 5-6)
- [ ] Beta test with friends/community to debug interaction systems
- [ ] Optimize generation costs and timing based on usage patterns
- [ ] Create channel branding and promotional content
- [ ] Set up analytics and monitoring for stream health and engagement
- [ ] Launch 24/7 stream with full interactive features
- [ ] Plan monetization strategy (donations, sponsorships, merchandise)

## 🎮 Interactive Features

### Chat Commands
- `!generate jazz rainy day` → Creates jazz track with rain ambiance
- `!mood upbeat study` → Generates upbeat focus music  
- `!theme halloween spooky` → Creates Halloween-themed lofi
- `!request piano instrumental` → Piano-focused generation
- `!vote A` → Vote for option A in polls

### Automated Features
- **Weather integration**: Real weather affects music mood
- **Time-based**: Late night → mellower tones, morning → energetic
- **Viewer count responsive**: More viewers → more energetic music
- **Seasonal themes**: Halloween spooky, Christmas cozy, summer beach vibes

### Community Engagement
- **Polls every 2 hours**: "Next vibe? A) Chill Jazz B) Lo-fi Hip Hop C) Ambient Electronic"
- **Request queue**: Users see their requests in line
- **Rating system**: Thumbs up/down affects future generation
- **Themed hours**: "Viewer Choice Hour" vs "AI Surprise Hour"

## 🏗️ Technical Architecture

### Server Components
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Chat Bot      │───▶│  Queue Manager   │───▶│   Music Gen     │
│ (YouTube API)   │    │  (Python)        │    │  (Suno API)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   OBS Studio     │◀───│  Scene Control  │
                       │  (Streaming)     │    │   (Visuals)     │
                       └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  YouTube Live    │
                       │   (RTMP)         │
                       └──────────────────┘
```

### File Structure
```
/opt/ai-music-stream/
├── src/
│   ├── main.py                 # Main application entry
│   ├── chat_bot.py            # YouTube chat monitoring
│   ├── music_generator.py     # Suno API integration
│   ├── queue_manager.py       # Request queue and scheduling
│   ├── obs_controller.py      # OBS scene management
│   └── prompt_generator.py    # Convert requests to prompts
├── config/
│   ├── .env                   # API keys and secrets
│   ├── obs_config.json       # OBS settings
│   └── prompts.json          # Prompt templates
├── music/                     # Generated music files
├── videos/                    # Background videos/animations
├── logs/                      # Application logs
└── scripts/                   # Utility scripts
```

## 🔑 Required API Keys & Setup

### APIs Needed
1. **YouTube Data API** - For chat monitoring
2. **Suno.ai API** (via third-party like sunoapi.com) - For music generation
3. **Adobe Firefly API** - For animated background generation
4. **YouTube Stream Key** - For RTMP streaming
5. **OpenWeather API** (optional) - For weather-responsive music

### Environment Variables (.env)
```bash
YOUTUBE_API_KEY=your_youtube_api_key
YOUTUBE_STREAM_KEY=your_stream_key
SUNO_API_KEY=your_suno_api_key
SUNO_API_URL=https://sunoapi.com/api/v1
ADOBE_FIREFLY_API_KEY=your_adobe_firefly_api_key
WEATHER_API_KEY=your_weather_api_key (optional)
```

## 🚀 Getting Started

1. **Purchase Contabo VPS** - €4.02/month plan
2. **Clone project**: `git clone <repo> && cd ai-music-stream`
3. **Run setup**: `chmod +x setup_server.sh && ./setup_server.sh`
4. **Configure APIs**: Edit `config/.env` with your API keys
5. **Start services**: `systemctl start virtual-display && systemctl start ai-music-stream`

## 🔄 Uptime & Maintenance Strategy

### Server Reboot Handling
24/7 streaming requires bulletproof uptime strategies for server reboots and updates:

#### **Option 1: Emergency Content Strategy (Budget - Single Server)**
- **Cost**: €4.02/month (single Contabo VPS)
- **Downtime**: 2-5 minutes during reboots
- **Method**: Pre-generated emergency playlists + YouTube Premieres

**Process**:
1. Before reboot: Generate 4-hour emergency playlist
2. Upload as YouTube Premiere (auto-starts streaming)
3. Reboot server during premiere playback
4. Resume live AI generation after restart
5. Seamless transition back to interactive stream

#### **Option 2: Dual Server Failover (Recommended for Growth)**
- **Cost**: €8.04/month (two Contabo VPS)  
- **Downtime**: 30 seconds
- **Method**: Primary/backup server with automated failover

**Architecture**:
```
Primary Server (€4.02/mo)  ──┐
                             ├─► YouTube Stream
Backup Server (€4.02/mo)   ──┘
```

**Failover Process**:
1. Backup monitors primary server health (10s intervals)
2. Primary failure detected → Backup takes over streaming
3. Same YouTube stream key → Seamless viewer experience  
4. Primary returns → Graceful handback to main server

### Update Strategies

#### **Hot Updates (Zero Downtime)**
- Individual component restarts (chat bot, music generator)
- Rolling updates with content buffering
- Code updates without stream interruption

#### **Maintenance Mode**
- Switch OBS to "maintenance loop" scene
- 2-hour pre-recorded music plays during updates
- "Quick update in progress" overlay for viewers
- Return to live generation after updates complete

### Emergency Scenarios

#### **Server Failure Recovery**
1. **Content Buffer**: Always maintain 2-4 hours of generated music
2. **Emergency Playlist**: Static backup content for catastrophic failures
3. **YouTube Premiere Fallback**: Pre-uploaded long-form videos
4. **Monitoring Alerts**: Instant notifications for stream interruptions

#### **Automated Recovery Scripts**
```bash
# scripts/safe_reboot.sh - Graceful server reboot
# scripts/deploy.sh - Zero-downtime updates  
# scripts/emergency_mode.sh - Disaster recovery
# scripts/health_check.sh - Continuous monitoring
```

### Implementation Priority
- **Phase 1**: Build emergency content system
- **Phase 2**: Implement graceful update procedures
- **Phase 3**: Add dual server failover (when revenue justifies cost)
- **Phase 4**: Advanced monitoring and auto-recovery

## 📈 Success Metrics

### Technical Goals
- 99% uptime for 24/7 streaming
- <30 second response time for music generation
- Handle 100+ concurrent chat commands
- <$10/month operational costs
- <5 minute downtime during planned maintenance

### Engagement Goals
- 50+ concurrent viewers within first month
- 20+ user interactions per hour
- 100+ unique songs generated per week
- Positive community feedback on interactivity

## 🎵 Unique Value Proposition
**First truly interactive AI music stream where viewers co-create content in real-time through chat commands, voting, and contextual AI that responds to weather, time, and community mood.**

---

**Status**: In Development  
**Started**: 2025-09-12  
**Target Launch**: 2025-10-15  
**Last Updated**: 2025-09-12
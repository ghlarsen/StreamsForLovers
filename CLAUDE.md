# CLAUDE CODE CONFIGURATION - AI MUSIC STREAMING PLATFORM
<!-- Project-specific configuration for Claude Code AI assistant -->

## 🎵 **PROJECT VISION**

**Transform from $18/month side project to $31k/month AI media empire**

**⚠️ BEFORE ANY DEVELOPMENT WORK:**
1. **MUST READ**: Bootstrap scaling strategy (Stage 1→4)
2. **MUST ACKNOWLEDGE**: Cost control limits for each stage
3. **MUST CONFIRM**: Understanding of interactive AI music generation
4. **MUST VERIFY**: API usage tracking is working

**⚠️ BEFORE ADDING NEW STREAMS:**
1. **RE-READ**: `BOOTSTRAP_PLAN.md` scaling requirements
2. **DOUBLE-CHECK**: Revenue thresholds met before scaling
3. **CONFIRM**: Stage exit criteria achieved
4. **VALIDATE**: Infrastructure can handle new load

**🚨 AUTOMATIC REJECTION TRIGGERS:**
If Claude Code attempts to scale beyond current stage without meeting criteria, **STOP IMMEDIATELY**:
- Adding Stage 2 streams without $200+ monthly profit
- Deploying Stage 3 without $1,000+ monthly revenue  
- Implementing Stage 4 without $3,000+ monthly revenue

## 📝 **MANDATORY SESSION MILESTONE WORKFLOW**

**⚠️ WHEN USER SAYS "SET A SESSION MILESTONE" OR SIMILAR:**
1. **IMMEDIATELY**: Push current changes to git with descriptive commit
2. **CREATE**: Detailed milestone document in `/documentation/dev_diary/`
3. **FILENAME FORMAT**: `YYYY-MM-DD_session_[descriptive-name].md`
4. **INCLUDE**: Current GitHub commit ID, progress summary, next steps
5. **TRACK**: Issues encountered, solutions applied, time spent

**TRIGGER PHRASES:**
- "set a session milestone"
- "save our progress"  
- "document this session"
- "create milestone"
- "checkpoint our work"

**MANDATORY MILESTONE CONTENT:**
```markdown
# Session Milestone: [Date] - [Descriptive Title]

**GitHub Commit**: `[commit-hash]`  
**Date**: YYYY-MM-DD HH:MM  
**Session Duration**: X hours  
**Stage**: Current development stage

## 🎯 **Objectives Achieved**
- [x] Completed task 1
- [x] Completed task 2  
- [ ] Partial progress on task 3

## 🚧 **Current Status**
- **What's Working**: List functional components
- **What's Broken**: List issues encountered
- **What's Next**: Immediate next steps

## 💡 **Key Learnings**
- Important discovery 1
- Problem solved: solution description
- Technical insight gained

## 🔧 **Technical Changes**
- Files modified: list key files
- APIs integrated: status of integrations
- Infrastructure: server/deployment status

## 🐛 **Issues & Solutions**
- **Issue**: Description
  **Solution**: How it was resolved
  **Prevention**: How to avoid in future

## 📊 **Metrics & Progress**
- Cost tracking: current spend vs budget
- Performance: any benchmarks or tests
- User feedback: if applicable

## 🎯 **Next Session Goals**
1. Priority task 1
2. Priority task 2
3. Priority task 3

## 📎 **Resources & Links**
- Relevant documentation links
- API endpoints used
- External resources referenced
```

**NO EXCEPTIONS**: Every milestone request triggers this complete workflow.

## 🚀 **DEVELOPMENT COMMANDS**

### **Server Management**
```bash
# Connect to production server
ssh root@161.97.116.47

# Deploy latest changes
./deploy.sh

# Check service status
systemctl status ai-music-stream
journalctl -u ai-music-stream -f

# Emergency procedures
./scripts/emergency_mode.sh --reason "manual_trigger"
./scripts/safe_reboot.sh
```

### **Local Development**
```bash
# Setup development environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Test API connections
python3 src/test_apis.py

# Generate test content
python3 src/generate_starter_content.py
```

### **Contabo Server Management**
```bash
# Install Contabo CLI
./scripts/contabo_management.sh install

# Provision new stage
./scripts/contabo_management.sh provision-stage-2

# Monitor costs
./scripts/contabo_management.sh costs
```

---

## 🏗️ **PROJECT OVERVIEW**
- **Name**: Interactive AI Music Streaming Platform
- **Revenue Target**: $31,400/month (Stage 4)
- **Architecture**: Multi-VPS + AI APIs + YouTube Live
- **Unique Value**: First truly interactive AI music streams

### **Bootstrap Stages**
- **Stage 1**: Single stream (City Pop Anime) - $18/month
- **Stage 2**: Dual stream (+Synthwave) - $45/month  
- **Stage 3**: Quad stream (+Ambient+Fitness) - $150/month
- **Stage 4**: Full platform (7 streams) - $860/month

---

## 🎭 **STREAMING PORTFOLIO**

### **Stage 1: Foundation**
- **City Pop Anime**: Lo-fi study music with anime aesthetics
- **Target**: 1,000+ concurrent viewers, $300-900/month

### **Stage 2: Expansion** 
- **Neon Synthwave**: Retro gaming/cyberpunk vibes
- **Target**: 2,000+ combined viewers, $600-1,800/month

### **Stage 3: Diversification**
- **Cosmic Ambient**: Meditation/sleep/focus
- **Fitness Beats**: Workout motivation music
- **Target**: 5,000+ viewers, $2,000-6,000/month

### **Stage 4: Empire**
- **Noir Jazz**: Sophisticated evening atmosphere
- **Desert Country**: Country/western landscapes  
- **Intimate Vibes**: Romantic/couples content
- **Target**: 15,000+ viewers, $8,500-31,400/month

---

## 📁 **PROJECT STRUCTURE**

```
/src/
├── main.py                    # Main orchestration system
├── chat_bot.py               # YouTube chat monitoring
├── music_generator.py        # Suno API integration
├── background_generator.py   # Video generation (MiniMax)
├── queue_manager.py          # Content scheduling
├── obs_controller.py         # OBS automation
└── suno_api_client.py       # Music API client

/scripts/
├── setup_server.sh           # Initial server setup
├── deploy.sh                 # Simple deployment
├── safe_reboot.sh           # Graceful server restart
├── emergency_mode.sh        # Disaster recovery
├── health_check.sh          # System monitoring
└── contabo_management.sh    # Multi-server provisioning

/config/
├── .env                     # Production configuration
└── .env.example            # Template configuration

/docs/
├── PROJECT_PLAN.md         # Master project roadmap
├── BOOTSTRAP_PLAN.md       # Scaling strategy
├── MULTI_STREAM_ARCHITECTURE.md  # Enterprise architecture
├── LAUNCH_CHECKLIST.md     # Go-live procedures
└── DEPLOYMENT_COMMANDS.md  # Server setup guide
```

---

## 🔐 **API ARCHITECTURE**

### **MUSIC GENERATION (Suno API)**
- **Provider**: SunoAPI.org (third-party)
- **Cost**: ~$0.01 per song
- **Daily Limit**: $0.60 budget control
- **Models**: V3.5 (balanced), V4 (quality), V4.5 (premium)

### **VIDEO GENERATION (MiniMax Hailuo)**
- **Provider**: MiniMax via API
- **Cost**: $95/month unlimited (Stage 3+)
- **Quality**: 1080p 30fps, seamless looping
- **Features**: Mood-responsive, genre-specific

### **STREAMING (YouTube Live)**
- **Platform**: YouTube Live RTMP
- **Quality**: 1080p 30fps, 5-10 Mbps upload
- **Bandwidth**: 32TB/month per server (Contabo)
- **Monitoring**: Real-time chat processing

---

## 🎯 **DEVELOPMENT PRIORITIES**

### **Current Stage: Stage 1 (City Pop Anime)**
- ✅ Suno API integration working
- ✅ GitHub repository with auto-deployment
- ✅ Contabo server provisioned
- 🔄 YouTube API keys acquisition
- 🔄 OBS streaming configuration
- 🔄 Chat monitoring system
- 🔄 MVP testing and launch

### **Stage 1 Exit Criteria (Before Stage 2)**
- ✅ 500+ concurrent viewers consistently
- ✅ $200+ monthly profit
- ✅ >95% system uptime
- ✅ Active chat community engagement

---

## 💰 **COST MONITORING**

### **Stage 1 Budget Breakdown**
```bash
# Monthly costs
Contabo VPS: €4.02 ($4.35)
Suno API: $3.60 (12 songs/day)
MiniMax: $10 (pay-per-use testing)
TOTAL: $18/month

# Daily limits
Music generation: $0.60/day max
Video generation: $0.33/day testing
```

### **Scaling Investment Requirements**
- **Stage 1→2**: $200+ monthly profit threshold
- **Stage 2→3**: $1,000+ monthly revenue threshold  
- **Stage 3→4**: $3,000+ monthly revenue threshold

---

## ⚡ **CLAUDE CODE BEST PRACTICES**

### **Always Check Before Changes**
```bash
# Verify current stage and budget
python3 -c "from src.suno_api_client import SunoAPIClient; client = SunoAPIClient(); print(client.get_usage_stats())"

# Check system health
./scripts/health_check.sh

# Verify service status
systemctl status ai-music-stream virtual-display
```

### **After Any Code Changes**
```bash
# Test locally first
python3 src/main.py --test-mode

# Deploy to production
./deploy.sh

# Monitor deployment
ssh root@161.97.116.47 'tail -f /var/log/ai-stream-deploy.log'
```

### **Content Generation Patterns**
- **Music**: Genre-specific prompts with mood variations
- **Video**: 30-second seamless loops, 1080p quality
- **Chat**: Real-time sentiment analysis and response
- **Queue**: Always maintain 2-4 hours buffer content

---

## 🚨 **CRITICAL CONSTRAINTS**

### **DO NOT EXCEED BUDGETS**
- Stage 1: $18/month total operational cost
- Daily music generation: $0.60 maximum
- Video generation: Only as needed for testing

### **DO NOT SCALE PREMATURELY**
- No Stage 2 without Stage 1 success metrics
- No additional servers without revenue justification
- No enterprise features until Stage 3+

### **DO NOT MODIFY CORE FILES** (Without Testing)
- `/src/main.py` - Main orchestration
- `/config/.env` - Production configuration
- `/scripts/emergency_mode.sh` - Disaster recovery

---

## 🌍 **SCALING ARCHITECTURE**

### **Stage 2: Dual Stream**
- Add Neon Synthwave stream
- Implement basic orchestration
- Cross-stream analytics

### **Stage 3: Professional Platform**  
- Master orchestration server
- Advanced chat sentiment analysis
- DSP distribution (Spotify, Apple Music)

### **Stage 4: Full Enterprise**
- 7-stream ecosystem
- Advanced AI features
- Multi-platform distribution
- Enterprise monitoring

---

## 💡 **INTERACTIVE FEATURES**

### **Chat Commands**
```
!generate jazz rainy day    # Generate specific music
!mood upbeat study          # Set mood-based generation  
!theme halloween spooky     # Themed content request
!vote A                     # Vote in polls
```

### **Automated Features**
- **Time-based**: Morning energy → evening chill
- **Weather-responsive**: Real weather affects music mood
- **Viewer-responsive**: More viewers → more energetic music
- **Seasonal**: Holiday themes, seasonal changes

### **Community Engagement**
- **Polls**: Every 2 hours for next track theme
- **Request queue**: Visible to all viewers
- **Rating system**: Community feedback shapes generation
- **Cross-stream**: Audience migration between related streams

---

## 🔧 **TROUBLESHOOTING**

### **Common Issues**
1. **Stream goes offline**: Check emergency_mode.sh logs
2. **Music generation fails**: Verify Suno API budget/limits
3. **High costs**: Review generation frequency settings
4. **Chat not responding**: Check YouTube API connectivity

### **Debug Commands**
```bash
# Check API connectivity
python3 -c "from src.suno_api_client import SunoAPIClient; client = SunoAPIClient(); client.initialize()"

# Monitor system resources
free -h && df -h && systemctl list-units --failed

# View real-time logs
journalctl -u ai-music-stream -f
```

### **Emergency Procedures**
```bash
# Immediate emergency mode
./scripts/emergency_mode.sh --reason "manual_trigger" --auto-recovery

# Safe server restart
./scripts/safe_reboot.sh

# Check all system health
./scripts/health_check.sh
```

---

## 📊 **SUCCESS METRICS**

### **Stage 1 KPIs**
- **Viewers**: 500+ concurrent consistently
- **Engagement**: 50+ chat interactions/hour
- **Uptime**: >95% stream availability
- **Cost Control**: <$18/month operational
- **Revenue**: $200+ monthly profit

### **Business Growth Tracking**
- **Monthly Recurring Revenue**: Track growth trajectory
- **Cost Per Viewer**: Optimize efficiency
- **Content Library**: Unique songs generated
- **Community Size**: Subscriber growth rate

---

## 🎉 **CURRENT STATUS**

### **✅ Infrastructure Complete:**
- Contabo VPS provisioned (161.97.116.47)
- GitHub repository with auto-deployment
- Suno API integrated and configured
- MiniMax Hailuo API ready
- Bootstrap scaling plan documented

### **🔄 In Progress:**
- YouTube API key acquisition
- OBS streaming configuration  
- Chat monitoring system development

### **📅 Next Steps:**
- Complete Stage 1 MVP deployment
- Launch City Pop Anime stream
- Achieve Stage 1 exit criteria
- Plan Stage 2 expansion

---

## 🎵 **UNIQUE VALUE PROPOSITION**

**"First truly interactive AI music stream where viewers co-create content in real-time through chat commands, voting, and contextual AI that responds to weather, time, and community mood."**

### **Competitive Advantages**
- **Real-time AI interaction** (unprecedented)
- **Multi-genre diversification** (risk mitigation)
- **Scalable architecture** (rapid expansion capability)
- **Community-driven content** (higher engagement)
- **Cross-stream synergies** (audience network effects)

---

**Last Updated**: 2025-09-13  
**Current Stage**: Stage 1 (City Pop Anime MVP)  
**Server**: 161.97.116.47 (Contabo VPS)  
**Repository**: https://github.com/ghlarsen/StreamsForLovers.git  
**Revenue Target**: $31,400/month (Stage 4)  
**Current Investment**: $18/month
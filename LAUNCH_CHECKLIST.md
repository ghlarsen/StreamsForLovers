# Stage 1 Launch Checklist: City Pop Anime Stream 🎵✨

## Pre-Launch Setup (Today/Tomorrow)

### 1. Infrastructure Setup
- [ ] **Purchase Contabo VPS** (€4.02/month plan)
  - 3 vCPU cores, 8GB RAM, 75GB NVMe, 32TB traffic
  - Location: Choose closest to your target audience
  - Save login credentials securely

- [ ] **SSH Access Setup**
  - Generate SSH key pair
  - Configure secure access to VPS
  - Test connection: `ssh root@your-server-ip`

### 2. Server Configuration
- [ ] **Run Setup Script**
  ```bash
  git clone <your-repo>
  cd "Streams for Lovers"
  chmod +x setup_server.sh
  ./setup_server.sh
  ```

- [ ] **Configure Environment**
  ```bash
  cp config/.env.example config/.env
  nano config/.env  # Add your API keys
  ```

### 3. API Keys Required

#### ✅ Already Have:
- [x] **Suno API**: `b4ec4a1698ed35aeaa76280d62fb8c77`

#### 🔑 Still Need:
- [ ] **YouTube Data API Key**
  - Go to: https://console.developers.google.com
  - Create project → Enable YouTube Data API v3
  - Create credentials → API Key
  - **Estimated time**: 10 minutes

- [ ] **YouTube Live Stream Key**
  - Go to: https://studio.youtube.com
  - Create → Go Live → Stream
  - Copy "Stream key"
  - **Channel requirement**: Need 50+ subscribers OR verified phone
  - **Estimated time**: 5 minutes (if eligible)

- [ ] **MiniMax Hailuo API Key**
  - Go to: https://api.minimax.chat (or fal.ai for MiniMax access)
  - Sign up → Get API key
  - Start with pay-per-use (~$10/month for testing)
  - **Estimated time**: 15 minutes

### 4. Channel Setup
- [ ] **Create YouTube Channel**
  - Channel name: "City Pop Anime Lounge" (or similar)
  - Channel art: Anime aesthetic with city pop vibes
  - Description: "AI-generated city pop & lo-fi beats that respond to your chat!"

- [ ] **Channel Branding**
  - Logo: Anime girl studying with city lights
  - Banner: Tokyo cityscape with retro aesthetics
  - Thumbnail template: Consistent anime style

### 5. Content Preparation
- [ ] **Generate Initial Content**
  - 10 starter songs with City Pop prompts
  - 5 background videos (cozy study room themes)
  - Emergency playlist (4 hours of content)

- [ ] **Test Generation Pipeline**
  ```bash
  python3 src/test_apis.py  # Test all API connections
  python3 src/generate_starter_content.py  # Create initial library
  ```

## Launch Day (When Ready)

### 6. Technical Testing
- [ ] **OBS Configuration Test**
  - Virtual display working
  - Audio routing correct
  - Scene transitions smooth
  - RTMP connection stable

- [ ] **Chat Monitoring Test**
  - Commands responding: `!generate`, `!mood`, `!request`
  - Sentiment analysis working
  - Queue management functional

- [ ] **API Integration Test**
  - Suno generating music successfully
  - MiniMax creating videos
  - Error handling working
  - Cost tracking accurate

### 7. Go Live Process
- [ ] **Pre-Stream**
  - Start all services: `systemctl start ai-music-stream`
  - Check logs: `journalctl -u ai-music-stream -f`
  - Verify health: `curl localhost:8080/health`

- [ ] **Stream Launch**
  - Start YouTube Live stream
  - Post launch announcement on social media
  - Monitor initial viewer response
  - Test chat commands with friends

### 8. First Week Monitoring
- [ ] **Daily Checks**
  - Viewer count trends
  - Chat engagement levels
  - Content generation success rate
  - System uptime percentage
  - Cost tracking (target: <$0.60/day)

## Success Metrics Tracking

### Week 1 Targets
- [ ] **Viewers**: 50+ concurrent (growing daily)
- [ ] **Uptime**: >90% stream availability
- [ ] **Engagement**: 10+ chat messages/hour
- [ ] **Content**: 84 unique songs generated
- [ ] **Costs**: <$18 total

### Week 2 Targets  
- [ ] **Viewers**: 100+ concurrent
- [ ] **Uptime**: >95% stream availability
- [ ] **Engagement**: 25+ chat messages/hour
- [ ] **Content**: 168 unique songs generated
- [ ] **Revenue**: First monetization signs

### Month 1 Exit Criteria
- [ ] **Viewers**: 500+ concurrent consistently
- [ ] **Revenue**: $200+ monthly profit
- [ ] **Uptime**: >95% average
- [ ] **Community**: Active, engaged chat community
- [ ] **Content**: 360+ unique songs in library

## Troubleshooting Quick Reference

### Common Issues & Fixes
- **Stream goes offline**: Check `scripts/emergency_mode.sh`
- **APIs failing**: Check `scripts/health_check.sh`
- **High costs**: Review generation frequency settings
- **Low engagement**: Adjust chat response sensitivity
- **Poor audio quality**: Check OBS audio settings

### Emergency Contacts
- **VPS Issues**: Contabo support
- **YouTube Issues**: Creator support
- **API Issues**: Check status pages
- **Code Issues**: Check GitHub issues/docs

## Stage 2 Preparation (Future)

### When to Scale (Trigger: $200+ monthly profit)
- [ ] Architecture design for dual streams
- [ ] Second Contabo VPS purchase
- [ ] Neon Synthwave channel creation
- [ ] Multi-stream orchestration testing

---

## 🎯 Priority Order for Launch

**High Priority (Must Have)**:
1. Contabo VPS setup ⭐⭐⭐
2. YouTube API keys ⭐⭐⭐
3. Basic OBS streaming ⭐⭐⭐
4. Suno music generation ⭐⭐⭐

**Medium Priority (Should Have)**:
5. MiniMax video generation ⭐⭐
6. Chat monitoring system ⭐⭐
7. Channel branding ⭐⭐

**Low Priority (Nice to Have)**:
8. Advanced analytics ⭐
9. Perfect visual polish ⭐
10. Complex chat features ⭐

**Remember**: Launch with minimum viable product, iterate based on real user feedback! 🚀
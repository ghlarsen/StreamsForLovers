# Git Branching Strategy - AI Music Streaming Platform

## 🎯 **Why We Need This**

**Live streaming = public mistakes.** With real viewers watching, we need a safe environment to test:
- New AI music prompts and styles
- Chat command features
- Visual background changes
- API integrations and limits
- Performance optimizations

## 🌟 **Branch Structure**

### **Production Branch: `main`**
- **Purpose**: Live public streaming
- **Server**: 161.97.116.47 (production service)
- **YouTube**: Public "City Pop Anime Lounge" stream
- **API Budget**: Full production limits ($0.60/day music)
- **Deployment**: Automatic on push to main
- **Monitoring**: Full health checks, emergency failover

### **Development Branch: `dev`**
- **Purpose**: Feature testing and validation
- **Server**: Same VPS, separate service (port 8081)
- **YouTube**: Private "City Pop DEV - TESTING" stream
- **API Budget**: Limited testing budget ($0.20/day)
- **Deployment**: Manual testing deployment
- **Monitoring**: Basic health checks

### **Feature Branches: `feature/[name]`**
- **Purpose**: Individual feature development
- **Examples**: `feature/chat-voting`, `feature/weather-integration`
- **Merge**: dev → feature testing → main
- **Lifecycle**: Create → develop → test → merge → delete

### **Hotfix Branches: `hotfix/[issue]`**
- **Purpose**: Emergency production fixes
- **Examples**: `hotfix/stream-crash`, `hotfix/api-limit-exceeded`
- **Merge**: Direct to main + backport to dev
- **Lifecycle**: Create → fix → deploy → merge → delete

## 🔄 **Development Workflow**

### **Normal Feature Development**
```bash
# 1. Start new feature
git checkout dev
git pull origin dev
git checkout -b feature/chat-voting

# 2. Develop and test locally
# ... make changes ...
git add . && git commit -m "Add chat voting system"

# 3. Test on dev environment
git push origin feature/chat-voting
# Deploy to dev server for testing

# 4. Merge to dev for integration testing
git checkout dev
git merge feature/chat-voting
git push origin dev

# 5. Deploy to dev environment
./deploy.sh dev

# 6. Test with private stream
# Test all features with private YouTube stream

# 7. Merge to production when ready
git checkout main
git merge dev
git push origin main

# 8. Auto-deploy to production
# Production deployment triggers automatically
```

### **Emergency Hotfix Workflow**
```bash
# 1. Create hotfix from main
git checkout main
git checkout -b hotfix/stream-crash

# 2. Fix the critical issue
# ... emergency fixes ...
git add . && git commit -m "Fix stream crash on chat command"

# 3. Deploy to production immediately
git checkout main
git merge hotfix/stream-crash
git push origin main

# 4. Backport to dev
git checkout dev
git merge hotfix/stream-crash
git push origin dev

# 5. Clean up
git branch -d hotfix/stream-crash
```

## 🏗️ **Infrastructure Setup**

### **Production Environment (main branch)**
```yaml
Service: ai-music-stream-prod
Port: 8080
Config: /opt/ai-music-stream/config/.env.prod
YouTube Stream: Public stream key
API Limits: Full production budget
Monitoring: Full health checks + alerts
Auto-restart: Yes
Emergency Mode: Full failover system
```

### **Development Environment (dev branch)**
```yaml  
Service: ai-music-stream-dev
Port: 8081
Config: /opt/ai-music-stream/config/.env.dev
YouTube Stream: Private test stream key
API Limits: Limited testing budget
Monitoring: Basic health checks
Auto-restart: No (manual testing)
Emergency Mode: Simple fallback
```

### **Configuration Differences**

**Production (.env.prod)**
```bash
ENVIRONMENT=production
YOUTUBE_STREAM_KEY=live_production_key_here
SUNO_API_DAILY_BUDGET=0.60
STREAM_TITLE="City Pop Anime - Interactive AI Music 🎵✨"
DEBUG_MODE=false
HEALTH_CHECK_INTERVAL=60
EMERGENCY_MODE_ENABLED=true
```

**Development (.env.dev)**
```bash
ENVIRONMENT=development  
YOUTUBE_STREAM_KEY=private_test_key_here
SUNO_API_DAILY_BUDGET=0.20
STREAM_TITLE="[DEV] City Pop Test - DO NOT SHARE"
DEBUG_MODE=true
HEALTH_CHECK_INTERVAL=300
EMERGENCY_MODE_ENABLED=false
```

## 🚀 **Deployment Scripts**

### **Enhanced deploy.sh**
```bash
#!/bin/bash
ENVIRONMENT=${1:-production}

if [ "$ENVIRONMENT" = "dev" ]; then
    echo "🧪 Deploying to DEVELOPMENT environment..."
    BRANCH="dev"
    SERVICE="ai-music-stream-dev"
    CONFIG=".env.dev"
else
    echo "🚀 Deploying to PRODUCTION environment..."
    BRANCH="main"  
    SERVICE="ai-music-stream-prod"
    CONFIG=".env.prod"
fi

# Deploy to specified environment
git push origin $BRANCH
ssh root@161.97.116.47 "
    cd /opt/ai-music-stream &&
    git checkout $BRANCH &&
    git pull origin $BRANCH &&
    cp config/$CONFIG config/.env &&
    systemctl restart $SERVICE
"

echo "✅ Deployed $BRANCH to $ENVIRONMENT"
```

## 🧪 **Testing Strategy**

### **Development Testing (Private Stream)**
1. **Feature Testing**: Test new features with private YouTube stream
2. **Prompt Testing**: Try new music prompts/styles safely
3. **Load Testing**: Test with simulated chat load
4. **Integration Testing**: Verify all components work together
5. **Cost Testing**: Monitor API usage in controlled environment

### **Production Readiness Checklist**
- [ ] All features tested in dev environment
- [ ] Private stream testing completed successfully
- [ ] API usage within expected limits
- [ ] No errors in dev logs for 24 hours
- [ ] Performance meets production requirements
- [ ] Emergency scenarios tested

## 📊 **Branch Protection Rules**

### **Main Branch Protection**
- Require pull request reviews: Yes
- Require status checks: Yes (CI/CD tests)
- Require up-to-date branches: Yes  
- Include administrators: No (emergency access)

### **Dev Branch Protection**
- Require pull request reviews: No (faster iteration)
- Require status checks: Yes (basic tests)
- Allow force pushes: Yes (development flexibility)

## 🔍 **Monitoring & Alerts**

### **Production Monitoring**
- Stream uptime alerts
- API budget alerts (80% of daily limit)
- Error rate monitoring
- Viewer count tracking
- Emergency mode activation alerts

### **Development Monitoring**  
- Basic health checks
- API usage tracking
- Feature testing results
- Performance benchmarks

## 🎯 **Stage-Specific Considerations**

### **Stage 1 (Current): Single Stream**
- Simple dev/prod setup on same server
- Private test stream for development
- Manual testing and validation

### **Stage 2+: Multi-Stream**
- Separate dev environment per stream
- Orchestrated testing across streams
- Automated testing pipelines

### **Stage 4: Enterprise**
- Full CI/CD pipeline
- Automated testing and deployment
- Blue-green deployments
- Comprehensive monitoring

## 🛠️ **Implementation Steps**

### **Phase 1: Setup Development Environment**
1. Create `dev` branch from `main`
2. Set up development service on server
3. Create private YouTube test stream
4. Configure development API keys
5. Test deployment to dev environment

### **Phase 2: Establish Workflow**
1. Create feature branch for testing
2. Test complete workflow dev → main
3. Validate both environments work independently
4. Train team on branching strategy

### **Phase 3: Production Hardening**
1. Set up branch protection rules
2. Add automated testing
3. Configure monitoring and alerts
4. Document emergency procedures

## 📝 **Branch Naming Conventions**

### **Feature Branches**
- `feature/chat-voting-system`
- `feature/weather-integration`
- `feature/multi-genre-support`
- `feature/viewer-analytics`

### **Hotfix Branches**
- `hotfix/stream-crash-fix`
- `hotfix/api-limit-exceeded`
- `hotfix/chat-bot-timeout`
- `hotfix/obs-connection-lost`

### **Release Branches (Future)**
- `release/stage-2-preparation`
- `release/multi-stream-launch`
- `release/enterprise-features`

## 🎵 **Content Testing Strategy**

### **Music Prompt Testing**
- Test new genres in dev environment first
- Validate AI-generated content quality
- Check for inappropriate content
- Monitor generation costs

### **Visual Testing**
- Test new background themes privately
- Validate video loop quality
- Check resource usage
- Ensure brand consistency

### **Chat Feature Testing**
- Test new commands with friends
- Validate response accuracy
- Check for spam/abuse resistance
- Monitor performance impact

---

**This branching strategy ensures we can innovate rapidly while maintaining a stable, professional live stream for our growing audience!** 🚀
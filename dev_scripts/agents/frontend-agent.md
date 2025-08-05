# Pure Bliss Frontend Development Agent

## PROJECT: Pure Bliss React Native 0.75 Frontend Development
**GOAL**: Deliver high-performance React Native app supporting 107,500 customers/year with optimal UX

## CONSTRAINTS

- Use React Native 0.75 exclusively
- Follow component-based architecture
- Maintain 90% Jest test coverage
- Use TypeScript for type safety
- Integrate with Pure Bliss microservices
- Support 10,000 concurrent users

## RESPONSIBILITIES

### 1. **React Native Development**
- Build responsive UI components with TypeScript
- Implement Pure Bliss brand design system
- Optimize performance for 60fps animations
- Handle offline-first architecture
- Integrate push notifications

### 2. **Social Media Integration**
- Instagram API integration for content posting
- YouTube API for video uploads
- Hootsuite API for multi-platform management
- Real-time engagement metrics display
- Social analytics dashboard

### 3. **Order Management Frontend**
- Real-time order tracking interface
- Payment integration with Stripe API
- Order history and status updates
- Customer communication portal
- Menu browsing and customization

### 4. **Gamification Interface**
- BlissVibe quest display and tracking
- Location-based challenge interface
- Achievement and reward system
- Leaderboard and social features
- Progress visualization

### 5. **Testing and Quality**
- Jest unit tests for all components
- Integration tests for API calls
- E2E testing with Detox
- Performance profiling
- Accessibility compliance

## TECHNOLOGY STACK

### Core Framework
- **React Native**: 0.75 with TypeScript
- **Navigation**: React Navigation 6
- **State Management**: Redux Toolkit with RTK Query
- **UI Library**: React Native Elements + custom components
- **Animation**: React Native Reanimated 3

### Development Tools
- **Testing**: Jest + React Native Testing Library + Detox
- **Linting**: ESLint with TypeScript rules
- **Formatting**: Prettier with 2-space indent
- **Build**: Metro bundler with custom configuration
- **CI/CD**: GitHub Actions for automated testing

### API Integration
- **HTTP Client**: Axios with interceptors
- **Real-time**: WebSocket for live updates
- **Authentication**: OIDC tokens from Keycloak
- **Caching**: React Query for server state
- **Offline**: Redux Persist for offline support

## MICROSERVICES INTEGRATION

### Service Endpoints
- **Authentication**: https://dev.purebliss.app/keycloak
- **Order API**: Laravel 11 backend via Nginx proxy
- **Social Media**: Hootsuite/Instagram/YouTube APIs
- **Gamification**: BlissVibe engine API
- **Analytics**: Prometheus metrics via custom API

### Security Requirements
- OIDC token-based authentication
- API request signing for sensitive operations
- Certificate pinning for API calls
- Secure storage for user credentials
- Data encryption at rest and in transit

## PERFORMANCE TARGETS

### User Experience
- **App Launch**: <2 seconds cold start
- **Screen Navigation**: <100ms transition
- **API Responses**: <300ms perceived latency
- **Offline Support**: 7-day cached content
- **Battery Usage**: <5% drain per hour active use

### Technical Metrics
- **Bundle Size**: <50MB total app size
- **Memory Usage**: <200MB peak consumption
- **CPU Usage**: <30% sustained load
- **Crash Rate**: <0.1% sessions
- **Test Coverage**: >90% code coverage

## PURE BLISS SPECIFIC FEATURES

### Customer Management
- Profile management and preferences
- Order history and favorites
- Loyalty program integration
- Referral tracking system
- Customer support chat

### Social Media Automation
- Content scheduling interface
- Hashtag optimization suggestions
- Engagement analytics display
- Multi-platform posting preview
- Performance metrics dashboard

### Gamification Components
- Quest progress indicators
- Achievement notification system
- Location-based challenges
- Social sharing capabilities
- Reward redemption interface

## DEVELOPMENT WORKFLOW

### Code Organization
```
src/
├── components/          # Reusable UI components
├── screens/            # Screen components
├── navigation/         # Navigation configuration
├── services/           # API services and utilities
├── store/             # Redux store and slices
├── hooks/             # Custom React hooks
├── utils/             # Helper functions
├── types/             # TypeScript type definitions
└── __tests__/         # Test files
```

### Component Standards
- Use functional components with hooks
- Implement proper error boundaries
- Follow Pure Bliss design system
- Ensure accessibility compliance
- Document complex components

### Testing Strategy
- Unit tests for all utility functions
- Component tests for UI interactions
- Integration tests for API flows
- E2E tests for critical user journeys
- Performance tests for animations

## API INTEGRATION PATTERNS

### Authentication Flow
```typescript
// OIDC token management
const authService = {
  login: async (credentials) => {
    const response = await keycloakAuth(credentials);
    await secureStorage.setItem('token', response.token);
    return response;
  },
  refreshToken: async () => {
    // Handle token refresh with Keycloak
  }
};
```

### Error Handling
- Implement global error boundary
- Network error retry logic
- User-friendly error messages
- Offline state management
- Crash reporting integration

## DEPLOYMENT CONFIGURATION

### Build Optimization
- Code splitting for lazy loading
- Image optimization and compression
- Bundle analysis and tree shaking
- Platform-specific optimizations
- ProGuard/R8 for Android release builds

### Environment Management
- Development, staging, production configs
- Feature flags for gradual rollouts
- A/B testing infrastructure
- Analytics and crash reporting
- Performance monitoring

## SUCCESS METRICS

### User Engagement
- Daily Active Users (DAU) growth
- Session duration >10 minutes average
- Feature adoption rates >80%
- User retention >70% after 30 days
- App store rating >4.5 stars

### Technical Performance
- 99.9% app availability
- <1% crash rate across all versions
- <300ms API response times
- 90%+ test coverage maintained
- Zero critical security vulnerabilities

### Business Impact
- Support 107,500 customers/year target
- Enable 1,750 orders/hour processing
- Facilitate 70 social posts/day automation
- Achieve ≥1.50% social engagement rate
- Maintain 99.999% backend service uptime

## ESCALATION PROTOCOLS

### Performance Issues
- Monitor app performance metrics
- Alert on crash rate >0.5%
- Track API response time degradation
- Report memory leaks immediately
- Escalate to infrastructure team for backend issues

### Security Concerns
- Immediately report authentication failures
- Monitor for API security breaches
- Track suspicious user behavior
- Coordinate with backend security team
- Implement emergency app updates if needed

PROJECT: Pure Bliss React Native 0.75 Frontend Development
GOAL: Deliver cross-platform mobile app supporting 107,500 customers/year with 99.999% uptime

IMMEDIATE PRIORITIES:
1. **Project Setup & Architecture** (Week 1)
   - Initialize React Native 0.75 project with TypeScript
   - Configure development environment with proper tooling
   - Set up component library and design system
   - Implement navigation structure
   - Configure state management with Redux Toolkit

2. **Core App Structure** (Week 1-2)
   - Authentication screens (login/register/forgot password)
   - Main navigation (bottom tabs + stack navigation)
   - Home screen with featured smoothies and quick actions
   - Menu browsing with categories and filtering
   - User profile and settings

3. **Order Management** (Week 2-3)
   - Shopping cart functionality
   - Checkout flow with payment integration
   - Order tracking and history
   - Real-time order status updates
   - Receipt and order confirmation

4. **Social Integration** (Week 3-4)
   - Camera integration for UGC creation
   - Social sharing capabilities
   - Instagram-style post creation
   - Content upload to backend
   - Social feed for community content

5. **Gamification Features** (Week 4-5)
   - BlissVibe quest dashboard
   - Points and rewards system
   - Achievement unlocking and display
   - Location-based challenges
   - Leaderboard and social competition

CONSTRAINTS:
- React Native 0.75 with TypeScript exclusively
- Support iOS 14+ and Android API 24+
- Offline-first architecture with proper sync
- 90% Jest test coverage minimum
- Bundle size under 50MB
- Cold start under 2 seconds
- Memory usage under 200MB peak

TECHNOLOGY STACK:
- **Framework**: React Native 0.75 + TypeScript
- **Navigation**: React Navigation 6
- **State**: Redux Toolkit + RTK Query
- **UI**: React Native Elements + custom components
- **Animation**: Reanimated 3 + Lottie
- **Storage**: AsyncStorage + Redux Persist
- **HTTP**: Axios with interceptors
- **Testing**: Jest + React Native Testing Library + Detox
- **Build**: Metro + Flipper for debugging

API ENDPOINTS:
- Authentication: https://dev.purebliss.app/keycloak
- Orders API: https://dev.purebliss.app/api/orders
- Menu API: https://dev.purebliss.app/api/menu
- Social API: https://dev.purebliss.app/api/social
- Gamification: https://dev.purebliss.app/api/gamification
- Analytics: https://dev.purebliss.app/api/analytics

DIRECTORY STRUCTURE:
```
pure-bliss-frontend/
├── src/
│   ├── components/          # Reusable UI components
│   │   ├── common/         # Button, Input, Modal, etc.
│   │   ├── forms/          # Form components
│   │   └── media/          # Image, Video components
│   ├── screens/            # Screen components
│   │   ├── auth/           # Login, Register screens
│   │   ├── home/           # Home and dashboard
│   │   ├── menu/           # Menu browsing
│   │   ├── orders/         # Order management
│   │   ├── social/         # Social features
│   │   ├── gamification/   # BlissVibe features
│   │   └── profile/        # User profile
│   ├── navigation/         # Navigation configuration
│   ├── services/           # API services
│   ├── store/             # Redux store setup
│   ├── hooks/             # Custom React hooks
│   ├── utils/             # Helper functions
│   ├── types/             # TypeScript definitions
│   └── assets/            # Images, fonts, etc.
├── __tests__/             # Test files
├── android/               # Android-specific code
├── ios/                   # iOS-specific code
├── package.json
├── tsconfig.json
├── babel.config.js
├── metro.config.js
└── README.md
```

DEVELOPMENT PHASES:

**Phase 1: Foundation (Days 1-5)**
- Project initialization and tooling setup
- Basic navigation structure
- Authentication screens
- API service layer setup
- Design system implementation

**Phase 2: Core Features (Days 6-10)**
- Home screen with smoothie showcase
- Menu browsing and search
- Shopping cart implementation
- Basic order flow
- User profile management

**Phase 3: Advanced Features (Days 11-15)**
- Payment integration with Stripe
- Real-time order tracking
- Push notifications setup
- Camera and media handling
- Social sharing capabilities

**Phase 4: Gamification (Days 16-20)**
- BlissVibe quest system
- Points and rewards UI
- Achievement system
- Location-based features
- Leaderboard implementation

**Phase 5: Polish & Testing (Days 21-25)**
- Performance optimization
- Comprehensive testing
- Error handling and edge cases
- App store preparation
- Documentation completion

COMPONENT ARCHITECTURE:
- Use functional components with hooks
- Implement proper error boundaries
- Follow atomic design principles
- Ensure accessibility compliance
- Optimize for performance and memory

TESTING STRATEGY:
- Unit tests for utilities and hooks
- Component tests for UI interactions
- Integration tests for API flows
- E2E tests for critical user journeys
- Performance testing for animations

PERFORMANCE TARGETS:
- App launch: <2 seconds cold start
- Screen transitions: <100ms
- API response handling: <300ms perceived latency
- Smooth 60fps animations
- Minimal battery drain (<5% per hour)

SUCCESS CRITERIA:
- Successfully handles 10,000+ concurrent users
- Supports all planned customer interactions
- Integrates seamlessly with backend services
- Passes all automated tests (90%+ coverage)
- Meets performance benchmarks
- Ready for app store deployment

INTEGRATION POINTS:
- Keycloak for authentication and user management
- Laravel backend for order processing
- Firebase for real-time features and push notifications
- Stripe for payment processing
- Hootsuite API for social media posting
- Google Maps for location features

SECURITY REQUIREMENTS:
- OIDC token-based authentication
- Certificate pinning for API calls
- Secure storage for sensitive data
- Input validation and sanitization
- Protection against common mobile vulnerabilities

This specification provides the foundation for a comprehensive frontend development effort using the tmux-orchestrator system.

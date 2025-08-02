# Pure Bliss Backend Development Agent

## PROJECT: Pure Bliss Laravel 11 API Backend Development
**GOAL**: Build scalable API supporting 107,500 customers/year with 1,750 orders/hour capacity

## CONSTRAINTS

- Use Laravel 11 with PHP 8.3 exclusively
- Follow microservices architecture principles
- Maintain 90% PHPUnit test coverage
- Implement Sanctum authentication
- Integrate with Keycloak for SSO
- Support horizontal scaling

## RESPONSIBILITIES

### 1. **API Development**
- RESTful API design with Laravel 11
- GraphQL endpoints for complex queries
- Real-time WebSocket connections
- API versioning and documentation
- Rate limiting and throttling

### 2. **Order Management System**
- Order processing pipeline (1,750/hour capacity)
- Payment integration with Stripe
- Inventory management and tracking
- Customer communication system
- Order status and tracking

### 3. **Social Media Backend**
- Hootsuite API integration
- Instagram/YouTube API management
- Content scheduling and automation
- Engagement analytics processing
- Social media metrics aggregation

### 4. **Gamification Engine**
- BlissVibe quest management
- Achievement and reward system
- Location-based challenge logic
- Leaderboard calculations
- User progress tracking

### 5. **Data Management**
- PostgreSQL optimization and queries
- Redis caching strategies
- Database migrations and seeding
- Backup and recovery procedures
- Data analytics and reporting

## TECHNOLOGY STACK

### Core Framework
- **Laravel**: 11.x with PHP 8.3
- **Database**: PostgreSQL 16 with Redis 7 caching
- **Authentication**: Laravel Sanctum + Keycloak OIDC
- **Queue**: Laravel Horizon with Redis
- **WebSockets**: Laravel Reverb for real-time features

### Development Tools
- **Testing**: PHPUnit + Laravel Dusk for E2E
- **Code Quality**: PHP-CS-Fixer + PHPStan level 8
- **API Documentation**: Laravel Scribe
- **Debugging**: Laravel Telescope in development
- **Monitoring**: Laravel Pulse for production

### External Integrations
- **Payment**: Stripe API for processing
- **Social Media**: Hootsuite, Instagram, YouTube APIs
- **Analytics**: Google Analytics 4 API
- **Email**: Laravel Mail with Mailgun
- **Storage**: Google Cloud Storage

## MICROSERVICES ARCHITECTURE

### Service Boundaries
- **Authentication Service**: User management and auth
- **Order Service**: Order processing and management
- **Social Media Service**: Content automation and analytics
- **Gamification Service**: Quests, achievements, rewards
- **Analytics Service**: Data aggregation and insights

### Inter-Service Communication
- **API Gateway**: Nginx reverse proxy
- **Service Discovery**: Docker Compose networking
- **Message Queues**: Redis-based job queues
- **Event Broadcasting**: Laravel Events for service coordination
- **Circuit Breaker**: Resilient API calls between services

### Database Design
```sql
-- Optimized for Pure Bliss requirements
CREATE TABLE orders (
    id UUID PRIMARY KEY,
    customer_id UUID NOT NULL,
    status VARCHAR(50) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE,
    INDEX idx_customer_orders (customer_id, created_at),
    INDEX idx_status_created (status, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE social_posts (
    id UUID PRIMARY KEY,
    platform VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    engagement_rate DECIMAL(5,4),
    INDEX idx_platform_scheduled (platform, scheduled_at)
);
```

## PERFORMANCE TARGETS

### API Performance
- **Response Time**: <30ms p99 for all endpoints
- **Throughput**: 1,750 orders/hour sustained
- **Concurrent Users**: 10,000 simultaneous connections
- **Database Queries**: <10ms average execution time
- **Cache Hit Rate**: >95% for frequently accessed data

### System Reliability
- **Uptime**: 99.999% availability
- **Error Rate**: <0.1% for all API calls
- **Queue Processing**: <30 seconds for background jobs
- **Memory Usage**: <512MB per PHP-FPM process
- **CPU Usage**: <70% sustained load

## PURE BLISS SPECIFIC ENDPOINTS

### Customer Management API
```php
// Routes for customer operations
Route::apiResource('customers', CustomerController::class);
Route::get('customers/{customer}/orders', [CustomerController::class, 'orders']);
Route::post('customers/{customer}/loyalty', [CustomerController::class, 'updateLoyalty']);
```

### Order Processing API
```php
// High-performance order endpoints
Route::post('orders', [OrderController::class, 'create']);
Route::get('orders/{order}/tracking', [OrderController::class, 'tracking']);
Route::patch('orders/{order}/status', [OrderController::class, 'updateStatus']);
Route::get('orders/analytics', [OrderController::class, 'analytics']);
```

### Social Media API
```php
// Social media automation endpoints
Route::post('social/posts', [SocialMediaController::class, 'createPost']);
Route::get('social/analytics', [SocialMediaController::class, 'analytics']);
Route::post('social/schedule', [SocialMediaController::class, 'schedule']);
Route::get('social/engagement', [SocialMediaController::class, 'engagement']);
```

### Gamification API
```php
// BlissVibe gamification endpoints
Route::get('quests', [QuestController::class, 'index']);
Route::post('quests/{quest}/complete', [QuestController::class, 'complete']);
Route::get('achievements', [AchievementController::class, 'index']);
Route::get('leaderboard', [LeaderboardController::class, 'index']);
```

## SECURITY IMPLEMENTATION

### Authentication & Authorization
```php
// Sanctum + Keycloak integration
class AuthController extends Controller
{
    public function login(LoginRequest $request)
    {
        // Validate with Keycloak OIDC
        $token = $this->keycloakService->authenticate($request->validated());
        
        // Create Sanctum token
        $user = User::findByKeycloakId($token['sub']);
        return $user->createToken('api-token')->plainTextToken;
    }
}
```

### Input Validation
```php
// Comprehensive request validation
class OrderRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'customer_id' => 'required|uuid|exists:customers,id',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|uuid|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1|max:100',
            'payment_method' => 'required|string|in:stripe,paypal',
        ];
    }
}
```

### API Rate Limiting
```php
// Dynamic rate limiting based on user tier
class DynamicRateLimit
{
    public function handle($request, Closure $next, $maxAttempts = 60)
    {
        $user = $request->user();
        $limit = $user->isPremium() ? 1000 : 60; // Premium users get higher limits
        
        return RateLimiter::attempt(
            'api:' . $user->id,
            $limit,
            function() use ($next, $request) {
                return $next($request);
            }
        );
    }
}
```

## CACHING STRATEGIES

### Redis Configuration
```php
// Multi-level caching for Pure Bliss
class CacheService
{
    public function getMenu(string $locationId): array
    {
        return Cache::tags(['menu', 'location:' . $locationId])
            ->remember("menu:{$locationId}", 3600, function() use ($locationId) {
                return $this->menuRepository->getByLocation($locationId);
            });
    }
    
    public function getUserSession(string $userId): array
    {
        return Cache::store('redis')
            ->remember("session:{$userId}", 1440, function() use ($userId) {
                return $this->userRepository->getSessionData($userId);
            });
    }
}
```

### Database Optimization
```php
// Optimized queries for high performance
class OrderRepository
{
    public function getRecentOrders(int $customerId, int $limit = 10): Collection
    {
        return Order::where('customer_id', $customerId)
            ->with(['items.product:id,name,price', 'payments:id,amount,status'])
            ->latest('created_at')
            ->limit($limit)
            ->get();
    }
    
    public function getOrderAnalytics(Carbon $startDate, Carbon $endDate): array
    {
        return DB::table('orders')
            ->selectRaw('
                DATE(created_at) as date,
                COUNT(*) as total_orders,
                SUM(total_amount) as revenue,
                AVG(total_amount) as average_order_value
            ')
            ->whereBetween('created_at', [$startDate, $endDate])
            ->groupBy('date')
            ->orderBy('date')
            ->get()
            ->toArray();
    }
}
```

## TESTING STRATEGY

### Unit Testing
```php
// Comprehensive PHPUnit tests
class OrderServiceTest extends TestCase
{
    use RefreshDatabase;
    
    public function test_create_order_processes_correctly(): void
    {
        $customer = Customer::factory()->create();
        $products = Product::factory()->count(3)->create();
        
        $orderData = [
            'customer_id' => $customer->id,
            'items' => $products->map(fn($p) => [
                'product_id' => $p->id,
                'quantity' => 2
            ])->toArray()
        ];
        
        $order = $this->orderService->create($orderData);
        
        $this->assertInstanceOf(Order::class, $order);
        $this->assertEquals('pending', $order->status);
        $this->assertCount(3, $order->items);
    }
}
```

### Integration Testing
```php
// API endpoint testing
class OrderApiTest extends TestCase
{
    use RefreshDatabase;
    
    public function test_create_order_endpoint(): void
    {
        $user = User::factory()->create();
        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/orders', [
                'customer_id' => $user->customer->id,
                'items' => [
                    ['product_id' => Product::factory()->create()->id, 'quantity' => 2]
                ]
            ]);
            
        $response->assertStatus(201)
            ->assertJsonStructure(['id', 'status', 'total_amount', 'created_at']);
    }
}
```

## DEPLOYMENT CONFIGURATION

### Environment Setup
```php
// Production-optimized configuration
return [
    'database' => [
        'connections' => [
            'pgsql' => [
                'host' => env('DB_HOST', 'postgres'),
                'port' => env('DB_PORT', '5432'),
                'database' => env('DB_DATABASE', 'purebliss'),
                'username' => env('DB_USERNAME'),
                'password' => env('DB_PASSWORD'),
                'options' => [
                    PDO::ATTR_PERSISTENT => true,
                    PDO::ATTR_EMULATE_PREPARES => false,
                ],
            ],
        ],
    ],
    
    'cache' => [
        'default' => 'redis',
        'stores' => [
            'redis' => [
                'driver' => 'redis',
                'connection' => 'cache',
                'serializer' => 'php',
            ],
        ],
    ],
    
    'queue' => [
        'default' => 'redis',
        'connections' => [
            'redis' => [
                'driver' => 'redis',
                'connection' => 'default',
                'queue' => env('REDIS_QUEUE', 'default'),
                'retry_after' => 90,
                'block_for' => null,
            ],
        ],
    ],
];
```

## MONITORING AND OBSERVABILITY

### Performance Monitoring
```php
// Custom metrics for Pure Bliss
class MetricsMiddleware
{
    public function handle($request, Closure $next)
    {
        $start = microtime(true);
        
        $response = $next($request);
        
        $duration = microtime(true) - $start;
        
        // Log to Prometheus via custom metrics
        app(PrometheusService::class)->increment('api_requests_total', [
            'method' => $request->method(),
            'endpoint' => $request->route()?->getName() ?? 'unknown',
            'status' => $response->getStatusCode(),
        ]);
        
        app(PrometheusService::class)->observe('api_request_duration_seconds', $duration, [
            'endpoint' => $request->route()?->getName() ?? 'unknown',
        ]);
        
        return $response;
    }
}
```

## SUCCESS METRICS

### Business KPIs
- Support 107,500 customers/year
- Process 1,750 orders/hour peak capacity
- Maintain 99.999% API uptime
- Achieve <30ms p99 response times
- Support 70 social posts/day automation

### Technical Metrics
- 90%+ PHPUnit test coverage
- <0.1% API error rate
- >95% cache hit rate
- <512MB memory per process
- Zero security vulnerabilities

### Development Metrics
- 95%+ code review coverage
- <1 day mean time to deployment
- <5 minutes mean time to recovery
- 100% automated testing pipeline
- Zero production hotfixes

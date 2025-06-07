# Admin Dashboard Technical Implementation Guide
**Companion to the Admin Analytics Dashboard Specification**

## Quick Start Implementation

### 1. Project Setup

```bash
# Create Next.js project with TypeScript
npx create-next-app@latest admin-dashboard --typescript --tailwind --app

# Navigate to project
cd admin-dashboard

# Install essential dependencies
npm install firebase firebase-admin @tanstack/react-query recharts d3 
npm install zustand date-fns react-hook-form lucide-react
npm install @tremor/react clsx tailwind-merge

# Dev dependencies
npm install -D @types/d3 @types/node
```

### 2. Firebase Admin Setup

#### `/lib/firebase-admin.ts`
```typescript
import { initializeApp, cert, getApps, App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

let app: App;

if (!getApps().length) {
  app = initializeApp({
    credential: cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
} else {
  app = getApps()[0];
}

export const adminAuth = getAuth(app);
export const adminDb = getFirestore(app);
```

### 3. Authentication Middleware

#### `/middleware.ts`
```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  const session = request.cookies.get('session');

  // Verify Firebase Admin session
  if (!session) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  try {
    const response = await fetch(`${request.nextUrl.origin}/api/auth/verify`, {
      headers: {
        Cookie: `session=${session.value}`,
      },
    });

    if (!response.ok) {
      throw new Error('Invalid session');
    }

    return NextResponse.next();
  } catch (error) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico|login).*)'],
};
```

### 4. Core Analytics Hooks

#### `/hooks/useUserAnalytics.ts`
```typescript
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { DateRange } from '@/types/analytics';

interface UserAnalyticsParams {
  userId?: string;
  dateRange: DateRange;
  metrics?: string[];
}

export function useUserAnalytics({ userId, dateRange, metrics }: UserAnalyticsParams) {
  return useQuery({
    queryKey: ['userAnalytics', userId, dateRange, metrics],
    queryFn: async () => {
      const params = new URLSearchParams({
        startDate: dateRange.start.toISOString(),
        endDate: dateRange.end.toISOString(),
        ...(metrics && { metrics: metrics.join(',') }),
      });

      const endpoint = userId 
        ? `/api/analytics/users/${userId}?${params}`
        : `/api/analytics/users?${params}`;

      const response = await fetch(endpoint);
      if (!response.ok) throw new Error('Failed to fetch analytics');
      
      return response.json();
    },
    staleTime: 60 * 1000, // 1 minute
    refetchInterval: 5 * 60 * 1000, // 5 minutes
  });
}

// Real-time updates hook
export function useRealtimeAnalytics() {
  const queryClient = useQueryClient();

  useEffect(() => {
    const ws = new WebSocket(process.env.NEXT_PUBLIC_WS_URL!);

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      
      // Update relevant queries
      if (data.type === 'userUpdate') {
        queryClient.invalidateQueries(['userAnalytics', data.userId]);
      }
    };

    return () => ws.close();
  }, [queryClient]);
}
```

### 5. Dashboard Components

#### `/components/dashboard/MetricCard.tsx`
```typescript
import { Card } from '@tremor/react';
import { TrendingUp, TrendingDown } from 'lucide-react';

interface MetricCardProps {
  title: string;
  value: string | number;
  change?: number;
  trend?: 'up' | 'down';
  onClick?: () => void;
  loading?: boolean;
}

export function MetricCard({ 
  title, 
  value, 
  change, 
  trend, 
  onClick,
  loading 
}: MetricCardProps) {
  if (loading) {
    return (
      <Card className="animate-pulse">
        <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
        <div className="h-8 bg-gray-200 rounded w-1/2"></div>
      </Card>
    );
  }

  return (
    <Card 
      className="cursor-pointer hover:shadow-lg transition-shadow"
      onClick={onClick}
    >
      <p className="text-sm text-gray-600">{title}</p>
      <p className="text-2xl font-bold mt-2">{value}</p>
      {change !== undefined && (
        <div className="flex items-center mt-2">
          {trend === 'up' ? (
            <TrendingUp className="w-4 h-4 text-green-500 mr-1" />
          ) : (
            <TrendingDown className="w-4 h-4 text-red-500 mr-1" />
          )}
          <span className={trend === 'up' ? 'text-green-500' : 'text-red-500'}>
            {Math.abs(change)}%
          </span>
        </div>
      )}
    </Card>
  );
}
```

#### `/components/charts/UserActivityChart.tsx`
```typescript
import { AreaChart, Card, Title } from '@tremor/react';
import { useMemo } from 'react';

interface DataPoint {
  date: string;
  'Active Users': number;
  'New Users': number;
  'Classifications': number;
}

export function UserActivityChart({ data }: { data: DataPoint[] }) {
  const chartData = useMemo(() => {
    return data.map(point => ({
      ...point,
      date: new Date(point.date).toLocaleDateString('en-US', { 
        month: 'short', 
        day: 'numeric' 
      }),
    }));
  }, [data]);

  return (
    <Card>
      <Title>User Activity Trends</Title>
      <AreaChart
        className="h-72 mt-4"
        data={chartData}
        index="date"
        categories={['Active Users', 'New Users', 'Classifications']}
        colors={['blue', 'green', 'amber']}
        showLegend={true}
        showGridLines={true}
        showAnimation={true}
      />
    </Card>
  );
}
```

### 6. User Management Table

#### `/components/users/UserTable.tsx`
```typescript
import { useState, useMemo } from 'react';
import { 
  Table, 
  TableHead, 
  TableRow, 
  TableHeaderCell,
  TableBody,
  TableCell,
  Badge,
  Button,
} from '@tremor/react';
import { MoreVertical, Edit, Trash2, Mail } from 'lucide-react';
import { useUsers } from '@/hooks/useUsers';
import { UserFilters } from './UserFilters';
import { UserDetailsModal } from './UserDetailsModal';

export function UserTable() {
  const [filters, setFilters] = useState({});
  const [selectedUser, setSelectedUser] = useState(null);
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  
  const { data: users, isLoading } = useUsers(filters);

  const handleBulkAction = async (action: string) => {
    // Implement bulk actions
    switch (action) {
      case 'export':
        await exportUsers(selectedUsers);
        break;
      case 'notify':
        // Open notification modal
        break;
      case 'delete':
        // Confirm and delete
        break;
    }
  };

  return (
    <div className="space-y-4">
      <UserFilters onFiltersChange={setFilters} />
      
      {selectedUsers.length > 0 && (
        <div className="flex gap-2 p-2 bg-blue-50 rounded">
          <span>{selectedUsers.length} users selected</span>
          <Button size="xs" onClick={() => handleBulkAction('export')}>
            Export
          </Button>
          <Button size="xs" onClick={() => handleBulkAction('notify')}>
            Send Notification
          </Button>
          <Button size="xs" color="red" onClick={() => handleBulkAction('delete')}>
            Delete
          </Button>
        </div>
      )}

      <Table>
        <TableHead>
          <TableRow>
            <TableHeaderCell>
              <input 
                type="checkbox"
                onChange={(e) => {
                  if (e.target.checked) {
                    setSelectedUsers(users?.map(u => u.id) || []);
                  } else {
                    setSelectedUsers([]);
                  }
                }}
              />
            </TableHeaderCell>
            <TableHeaderCell>User</TableHeaderCell>
            <TableHeaderCell>Status</TableHeaderCell>
            <TableHeaderCell>Level</TableHeaderCell>
            <TableHeaderCell>Classifications</TableHeaderCell>
            <TableHeaderCell>Last Active</TableHeaderCell>
            <TableHeaderCell>Actions</TableHeaderCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {users?.map((user) => (
            <TableRow key={user.id}>
              <TableCell>
                <input
                  type="checkbox"
                  checked={selectedUsers.includes(user.id)}
                  onChange={(e) => {
                    if (e.target.checked) {
                      setSelectedUsers([...selectedUsers, user.id]);
                    } else {
                      setSelectedUsers(selectedUsers.filter(id => id !== user.id));
                    }
                  }}
                />
              </TableCell>
              <TableCell>
                <div className="flex items-center gap-2">
                  <img 
                    src={user.photoUrl || '/default-avatar.png'} 
                    className="w-8 h-8 rounded-full"
                    alt={user.displayName}
                  />
                  <div>
                    <p className="font-medium">{user.displayName}</p>
                    <p className="text-sm text-gray-500">{user.email}</p>
                  </div>
                </div>
              </TableCell>
              <TableCell>
                <Badge color={user.isActive ? 'green' : 'gray'}>
                  {user.isActive ? 'Active' : 'Inactive'}
                </Badge>
              </TableCell>
              <TableCell>{user.level}</TableCell>
              <TableCell>{user.totalClassifications}</TableCell>
              <TableCell>{formatRelativeTime(user.lastActive)}</TableCell>
              <TableCell>
                <div className="flex gap-1">
                  <Button 
                    size="xs" 
                    variant="light"
                    onClick={() => setSelectedUser(user)}
                  >
                    <Edit className="w-4 h-4" />
                  </Button>
                  <Button size="xs" variant="light">
                    <Mail className="w-4 h-4" />
                  </Button>
                  <Button size="xs" variant="light" color="red">
                    <Trash2 className="w-4 h-4" />
                  </Button>
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {selectedUser && (
        <UserDetailsModal 
          user={selectedUser}
          onClose={() => setSelectedUser(null)}
        />
      )}
    </div>
  );
}
```

### 7. Real-time Analytics Pipeline

#### `/lib/analytics/pipeline.ts`
```typescript
import { adminDb } from '@/lib/firebase-admin';
import { BigQuery } from '@google-cloud/bigquery';
import Redis from 'ioredis';

const bigquery = new BigQuery();
const redis = new Redis(process.env.REDIS_URL!);

export class AnalyticsPipeline {
  private batchSize = 100;
  private batchInterval = 5000; // 5 seconds
  private eventQueue: AnalyticsEvent[] = [];

  async processEvent(event: AnalyticsEvent) {
    // Add to queue
    this.eventQueue.push(event);

    // Process immediately for real-time metrics
    await this.updateRealtimeMetrics(event);

    // Batch process for historical data
    if (this.eventQueue.length >= this.batchSize) {
      await this.processBatch();
    }
  }

  private async updateRealtimeMetrics(event: AnalyticsEvent) {
    const key = `realtime:${event.eventType}:${this.getCurrentMinute()}`;
    
    await redis.multi()
      .hincrby(key, 'count', 1)
      .hincrby(key, event.userId, 1)
      .expire(key, 300) // 5 minute TTL
      .exec();

    // Publish to WebSocket subscribers
    await this.publishRealtimeUpdate(event);
  }

  private async processBatch() {
    const events = [...this.eventQueue];
    this.eventQueue = [];

    // Write to Firestore for immediate queries
    const batch = adminDb.batch();
    events.forEach(event => {
      const ref = adminDb.collection('analytics_events').doc();
      batch.set(ref, event);
    });
    await batch.commit();

    // Stream to BigQuery for historical analysis
    await this.streamToBigQuery(events);

    // Update aggregated metrics
    await this.updateAggregations(events);
  }

  private async streamToBigQuery(events: AnalyticsEvent[]) {
    const dataset = bigquery.dataset('analytics');
    const table = dataset.table('events');
    
    const rows = events.map(event => ({
      ...event,
      timestamp: event.timestamp.toISOString(),
      insertId: event.id, // Deduplication
    }));

    await table.insert(rows, {
      skipInvalidRows: true,
      ignoreUnknownValues: true,
    });
  }

  private async updateAggregations(events: AnalyticsEvent[]) {
    // Group events by hour for aggregation
    const hourlyGroups = this.groupEventsByHour(events);

    for (const [hour, hourEvents] of Object.entries(hourlyGroups)) {
      const metrics = this.calculateMetrics(hourEvents);
      
      // Update Firestore aggregations
      await adminDb
        .collection('aggregated_analytics')
        .doc(`hourly_${hour}`)
        .set(metrics, { merge: true });

      // Update Redis for fast queries
      await redis.setex(
        `analytics:hourly:${hour}`,
        3600, // 1 hour TTL
        JSON.stringify(metrics)
      );
    }
  }

  private calculateMetrics(events: AnalyticsEvent[]): AggregatedMetrics {
    const users = new Set(events.map(e => e.userId));
    const classifications = events.filter(e => e.eventType === 'classification');
    
    return {
      users: {
        active: users.size,
        sessions: new Set(events.map(e => e.sessionId)).size,
      },
      events: {
        total: events.length,
        byType: this.groupBy(events, 'eventType'),
      },
      classifications: {
        total: classifications.length,
        byCategory: this.groupBy(
          classifications, 
          e => e.parameters.category
        ),
      },
      performance: {
        avgProcessingTime: this.average(
          events.map(e => e.parameters.processingTime).filter(Boolean)
        ),
      },
    };
  }
}
```

### 8. API Routes Implementation

#### `/app/api/analytics/users/[userId]/route.ts`
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { z } from 'zod';

const querySchema = z.object({
  startDate: z.string().datetime(),
  endDate: z.string().datetime(),
  metrics: z.string().optional(),
});

export async function GET(
  request: NextRequest,
  { params }: { params: { userId: string } }
) {
  try {
    // Validate query parameters
    const searchParams = Object.fromEntries(request.nextUrl.searchParams);
    const { startDate, endDate, metrics } = querySchema.parse(searchParams);

    // Get user profile
    const userDoc = await adminDb
      .collection('users')
      .doc(params.userId)
      .get();

    if (!userDoc.exists) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    // Get user events
    const eventsQuery = await adminDb
      .collection('analytics_events')
      .where('userId', '==', params.userId)
      .where('timestamp', '>=', new Date(startDate))
      .where('timestamp', '<=', new Date(endDate))
      .orderBy('timestamp', 'desc')
      .limit(1000)
      .get();

    const events = eventsQuery.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Get classifications
    const classificationsQuery = await adminDb
      .collection('classifications')
      .where('userId', '==', params.userId)
      .where('timestamp', '>=', new Date(startDate))
      .where('timestamp', '<=', new Date(endDate))
      .get();

    const classifications = classificationsQuery.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Calculate analytics
    const analytics = calculateUserAnalytics(events, classifications);

    return NextResponse.json({
      user: userDoc.data(),
      analytics,
      events: events.slice(0, 100), // Latest 100 events
      classifications: classifications.slice(0, 50), // Latest 50 classifications
    });
  } catch (error) {
    console.error('Error fetching user analytics:', error);
    return NextResponse.json(
      { error: 'Failed to fetch analytics' },
      { status: 500 }
    );
  }
}

// Update user details
export async function PUT(
  request: NextRequest,
  { params }: { params: { userId: string } }
) {
  try {
    const body = await request.json();
    
    // Validate admin permissions
    const session = await getServerSession(request);
    if (!session?.user?.isAdmin) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    // Update user
    await adminDb
      .collection('users')
      .doc(params.userId)
      .update({
        ...body,
        updatedAt: new Date(),
        updatedBy: session.user.id,
      });

    // Log admin action
    await logAdminAction({
      action: 'user_update',
      targetId: params.userId,
      changes: body,
      adminId: session.user.id,
    });

    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to update user' },
      { status: 500 }
    );
  }
}
```

### 9. WebSocket Server for Real-time Updates

#### `/websocket-server/index.ts`
```typescript
import { WebSocketServer } from 'ws';
import { adminDb } from './firebase-admin';

const wss = new WebSocketServer({ port: 8080 });
const clients = new Map<string, Set<WebSocket>>();

// Listen for Firestore changes
const unsubscribe = adminDb
  .collection('analytics_events')
  .orderBy('timestamp', 'desc')
  .limit(1)
  .onSnapshot((snapshot) => {
    snapshot.docChanges().forEach((change) => {
      if (change.type === 'added') {
        const event = change.doc.data();
        broadcastEvent(event);
      }
    });
  });

function broadcastEvent(event: AnalyticsEvent) {
  const message = JSON.stringify({
    type: 'analytics_update',
    event,
    timestamp: new Date().toISOString(),
  });

  // Broadcast to all connected clients
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

wss.on('connection', (ws, req) => {
  const userId = req.url?.split('?userId=')[1];
  
  if (userId) {
    if (!clients.has(userId)) {
      clients.set(userId, new Set());
    }
    clients.get(userId)!.add(ws);
  }

  ws.on('message', (message) => {
    // Handle client messages
    const data = JSON.parse(message.toString());
    
    switch (data.type) {
      case 'subscribe':
        // Subscribe to specific metrics
        break;
      case 'unsubscribe':
        // Unsubscribe from metrics
        break;
    }
  });

  ws.on('close', () => {
    // Clean up client connection
    if (userId && clients.has(userId)) {
      clients.get(userId)!.delete(ws);
      if (clients.get(userId)!.size === 0) {
        clients.delete(userId);
      }
    }
  });
});
```

### 10. Data Export Functionality

#### `/lib/export/userDataExport.ts`
```typescript
import { adminDb } from '@/lib/firebase-admin';
import { Parser } from 'json2csv';
import JSZip from 'jszip';

export async function exportUserData(userId: string): Promise<Blob> {
  const zip = new JSZip();

  // 1. Export user profile
  const userDoc = await adminDb.collection('users').doc(userId).get();
  const userData = userDoc.data();
  zip.file('profile.json', JSON.stringify(userData, null, 2));

  // 2. Export classifications
  const classifications = await adminDb
    .collection('classifications')
    .where('userId', '==', userId)
    .get();

  const classificationData = classifications.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
    timestamp: doc.data().timestamp.toDate().toISOString(),
  }));

  // JSON format
  zip.file('classifications.json', JSON.stringify(classificationData, null, 2));

  // CSV format
  const csvParser = new Parser({
    fields: ['id', 'itemName', 'category', 'timestamp', 'confidence'],
  });
  const csv = csvParser.parse(classificationData);
  zip.file('classifications.csv', csv);

  // 3. Export analytics events
  const events = await adminDb
    .collection('analytics_events')
    .where('userId', '==', userId)
    .orderBy('timestamp', 'desc')
    .limit(10000) // Limit for performance
    .get();

  const eventData = events.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
    timestamp: doc.data().timestamp.toDate().toISOString(),
  }));

  zip.file('analytics_events.json', JSON.stringify(eventData, null, 2));

  // 4. Export gamification data
  const gamificationDoc = await adminDb
    .collection('gamification_profiles')
    .doc(userId)
    .get();

  if (gamificationDoc.exists) {
    zip.file('gamification.json', JSON.stringify(gamificationDoc.data(), null, 2));
  }

  // 5. Generate summary report
  const summary = generateUserSummaryReport(userData, classificationData, eventData);
  zip.file('summary_report.html', summary);

  // Generate zip file
  return await zip.generateAsync({ type: 'blob' });
}

function generateUserSummaryReport(
  user: any,
  classifications: any[],
  events: any[]
): string {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <title>User Data Export - ${user.displayName}</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .section { margin-bottom: 30px; }
        .stat { background: #f0f0f0; padding: 10px; margin: 5px 0; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
      </style>
    </head>
    <body>
      <h1>User Data Export Report</h1>
      
      <div class="section">
        <h2>User Profile</h2>
        <div class="stat">Name: ${user.displayName}</div>
        <div class="stat">Email: ${user.email}</div>
        <div class="stat">User ID: ${user.id}</div>
        <div class="stat">Joined: ${new Date(user.createdAt).toLocaleDateString()}</div>
      </div>

      <div class="section">
        <h2>Activity Summary</h2>
        <div class="stat">Total Classifications: ${classifications.length}</div>
        <div class="stat">Total Events: ${events.length}</div>
        <div class="stat">Most Common Category: ${getMostCommonCategory(classifications)}</div>
      </div>

      <div class="section">
        <h2>Recent Classifications</h2>
        <table>
          <tr>
            <th>Date</th>
            <th>Item</th>
            <th>Category</th>
            <th>Confidence</th>
          </tr>
          ${classifications.slice(0, 10).map(c => `
            <tr>
              <td>${new Date(c.timestamp).toLocaleDateString()}</td>
              <td>${c.itemName}</td>
              <td>${c.category}</td>
              <td>${(c.confidence * 100).toFixed(1)}%</td>
            </tr>
          `).join('')}
        </table>
      </div>

      <div class="section">
        <p>Generated on: ${new Date().toLocaleString()}</p>
        <p>This report contains your personal data from the Waste Segregation App.</p>
      </div>
    </body>
    </html>
  `;
}
```

### 11. Performance Monitoring

#### `/lib/monitoring/performance.ts`
```typescript
import { adminDb } from '@/lib/firebase-admin';
import * as Sentry from '@sentry/nextjs';

interface PerformanceMetric {
  name: string;
  value: number;
  unit: string;
  tags?: Record<string, string>;
}

export class PerformanceMonitor {
  private metrics: PerformanceMetric[] = [];
  private flushInterval = 60000; // 1 minute

  constructor() {
    setInterval(() => this.flush(), this.flushInterval);
  }

  recordMetric(metric: PerformanceMetric) {
    this.metrics.push({
      ...metric,
      timestamp: new Date(),
    });

    // Send to Sentry for monitoring
    Sentry.metrics.gauge(metric.name, metric.value, {
      unit: metric.unit,
      tags: metric.tags,
    });
  }

  async recordApiCall(endpoint: string, duration: number, status: number) {
    this.recordMetric({
      name: 'api.response_time',
      value: duration,
      unit: 'milliseconds',
      tags: {
        endpoint,
        status: status.toString(),
      },
    });

    // Record to Firestore for historical analysis
    await adminDb.collection('api_metrics').add({
      endpoint,
      duration,
      status,
      timestamp: new Date(),
    });
  }

  async getPerformanceStats(timeRange: { start: Date; end: Date }) {
    const metrics = await adminDb
      .collection('api_metrics')
      .where('timestamp', '>=', timeRange.start)
      .where('timestamp', '<=', timeRange.end)
      .get();

    const data = metrics.docs.map(doc => doc.data());
    
    return {
      totalRequests: data.length,
      avgResponseTime: this.average(data.map(d => d.duration)),
      p95ResponseTime: this.percentile(data.map(d => d.duration), 0.95),
      errorRate: data.filter(d => d.status >= 400).length / data.length,
      endpointBreakdown: this.groupBy(data, 'endpoint'),
    };
  }

  private flush() {
    if (this.metrics.length === 0) return;

    // Batch write to Firestore
    const batch = adminDb.batch();
    this.metrics.forEach(metric => {
      const ref = adminDb.collection('performance_metrics').doc();
      batch.set(ref, metric);
    });

    batch.commit().catch(console.error);
    this.metrics = [];
  }
}

export const performanceMonitor = new PerformanceMonitor();
```

### 12. Environment Variables

#### `.env.local`
```env
# Firebase Admin
FIREBASE_PROJECT_ID=waste-segregation-app-df523
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@waste-segregation-app-df523.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"

# BigQuery
GOOGLE_CLOUD_PROJECT=waste-segregation-app-df523
GOOGLE_APPLICATION_CREDENTIALS=./service-account-key.json

# Redis
REDIS_URL=redis://localhost:6379

# WebSocket
NEXT_PUBLIC_WS_URL=ws://localhost:8080

# Sentry
SENTRY_DSN=https://...@o4505.ingest.sentry.io/...

# Admin Dashboard
ADMIN_EMAILS=pranay@example.com
SESSION_SECRET=your-secret-key-here
```

### 13. Deployment Configuration

#### `docker-compose.yml`
```yaml
version: '3.8'

services:
  dashboard:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - redis
      - websocket

  websocket:
    build: ./websocket-server
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl

volumes:
  redis-data:
```

### 14. Testing Setup

#### `__tests__/analytics.test.ts`
```typescript
import { render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { UserAnalyticsDashboard } from '@/components/UserAnalyticsDashboard';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: false },
  },
});

describe('UserAnalyticsDashboard', () => {
  it('displays user metrics correctly', async () => {
    const mockUser = {
      id: 'test-user-123',
      displayName: 'Test User',
      email: 'test@example.com',
      totalClassifications: 42,
    };

    render(
      <QueryClientProvider client={queryClient}>
        <UserAnalyticsDashboard userId={mockUser.id} />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Test User')).toBeInTheDocument();
      expect(screen.getByText('42')).toBeInTheDocument();
    });
  });
});
```

---

## Quick Reference Commands

```bash
# Development
npm run dev

# Build for production
npm run build

# Run tests
npm test

# Deploy to Vercel
vercel --prod

# Deploy to Google Cloud Run
gcloud run deploy admin-dashboard \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated

# Monitor logs
gcloud logging tail "resource.type=cloud_run_revision"
```

---

This implementation guide provides the technical foundation for building the admin analytics dashboard. The modular architecture allows for incremental development while maintaining scalability and performance.

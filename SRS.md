# Software Requirements Specification (SRS)
## JunkWunk - Marketplace Enhancement

**Version**: 2.0  
**Date**: November 20, 2025

---

## 1. Current System

**Existing Features:**
- User authentication (Buyer/Seller roles)
- Item listing with images
- Shopping cart and checkout
- Location-based discovery
- Category filtering (Donate, Recyclable, Non-Recyclable)
- Profile management

---

## 2. New Features

### 2.1 Smart Search & Filtering

**Requirements:**
- Autocomplete search suggestions
- Typo-tolerant search
- Filter by: material type, price range, quantity, location, seller rating, date
- Multiple filters simultaneously
- Sort by: relevance, price, distance, date, rating
- Visual search (upload photo to find similar items)
- Save filter preferences

---

### 2.2 In-App Chat

**Requirements:**
- Real-time messaging between buyer and seller
- Typing indicators
- Read receipts
- Image sharing in chat
- Quick reply templates
- Make offer/counter-offer system
- Offer history tracking
- Unread message badges
- Push notifications for new messages

---

### 2.3 Price Discovery

**Requirements:**
- Show average market price per material type
- Price trend charts (7-day, 30-day)
- Price range display (min-max)
- Alert sellers if price is above/below market
- "Make an Offer" bidding system
- Real-time bid notifications
- Bid history (anonymized)
- Auto-accept bids at reserve price
- Bulk/tiered pricing (quantity discounts)
- Price drop badges
- Price alerts for buyers

---

### 2.4 AI Image Recognition

**Requirements:**
- Auto-detect material type from photos
- Suggest category and subcategory
- Detect contamination/quality issues
- Require minimum 3 photos per listing
- Auto-fill listing details based on images
- Quality score (0-100) for each item
- Show similar items based on image
- Allow seller to override AI suggestions

---

### 2.5 Pickup/Delivery Scheduling

**Requirements:**
- Calendar view of available pickup slots
- Book specific time slots
- Prevent double-booking
- Real-time GPS tracking of delivery vehicle
- ETA display
- "Driver nearby" notifications
- Route optimization for multiple pickups
- Turn-by-turn navigation
- Photo proof of pickup
- Buyer confirmation of receipt
- Dispute handling (wrong quantity, item not received)

---

### 2.6 Rating & Review System

**Requirements:**
- Multi-dimensional ratings:
  - Material quality
  - Communication
  - Delivery timeliness
  - Quantity accuracy
  - Overall experience
- Verified reviews (only from completed transactions)
- Photo proof for quality complaints
- Seller response to reviews
- Trust badges:
  - Top Rated Seller (4.5+ stars, 50+ transactions)
  - Fast Responder (replies <1 hour)
  - Reliable Delivery (95%+ on-time)
  - Quality Verified (AI + manual check)
- Rating trends over time
- Filter reviews by material type
- Show response rate to negative reviews

---

### 2.7 Smart Notifications

**Requirements:**
- Personalized notifications for:
  - New messages
  - Price drops on watched items
  - Bid updates
  - Pickup reminders
  - Payment received
  - New items matching saved searches
- User-configurable preferences:
  - Event types
  - Channels (push, email, SMS)
  - Quiet hours
  - Frequency (instant, hourly, daily digest)
- Smart timing (send when user likely to engage)
- Notification spam prevention (max 5/day)
- In-app notification center
- Quick actions from notifications
- Deep linking to relevant content

---

### 2.8 Saved Searches & Watchlists

**Requirements:**
- Save search queries
- Notifications for new matches
- Edit/delete saved searches
- Favorite/watchlist items
- Price change alerts on favorited items
- Bulk actions (remove all, compare)
- Follow favorite sellers
- Notifications when followed sellers list new items
- Show follower count on profiles

---

### 2.9 Seller Analytics Dashboard

**Requirements:**
- Performance metrics:
  - Total listing views
  - Conversion rate (views → sales)
  - Average response time
  - Rating trends
  - Revenue over time
- Per-listing analytics:
  - View count
  - Favorite count
  - Inquiry count
  - Price competitiveness
- Competitive analysis:
  - Average prices for similar items
  - Top-performing listings
  - Optimal pricing suggestions
  - Market demand trends
- Weekly/monthly reports

---

### 2.10 Quick Actions

**Requirements:**
- Quick list button (reuse previous listing details)
- Duplicate listings with edits
- Bulk listing upload
- Swipe gestures:
  - Swipe right to favorite
  - Swipe left to hide/remove
  - Long press for quick menu
- Haptic feedback
- Voice commands (optional):
  - "Search for plastic"
  - "Show my messages"
  - "List new item"

---

## 3. Non-Functional Requirements

**Performance:**
- App loads in <3 seconds on 3G
- Search results in <2 seconds
- Progressive image loading
- Offline mode for saved items and messages
- Auto-sync when online

**Usability:**
- Works on 2GB RAM devices
- New users complete first transaction in <5 minutes
- Light and dark modes
- Adjustable font sizes
- Hindi and English support (minimum)

**Security:**
- Secure payment gateways
- Encrypted data (rest and transit)
- Private chat messages
- Report suspicious activity

**Reliability:**
- 99% uptime
- Auto-retry failed transactions
- Confirmation for critical actions
- Daily backups

---

## 4. Success Metrics

**User Engagement:**
- 30%+ daily active users
- 8+ minutes average session
- 60%+ return within 7 days
- 70%+ try chat in first week

**Transactions:**
- <5 searches per purchase
- 2 hour average response time
- 80%+ transaction completion
- 40%+ repeat purchases

**Quality:**
- 4.2+ average rating
- <5% dispute rate
- 90%+ AI accuracy
- 95%+ on-time delivery

**Growth:**
- 20%+ monthly user growth
- 50+ new listings daily
- 30%+ quarterly GMV growth
- 15%+ referral rate

---

## 5. Implementation Priority

**Phase 1 (Months 1-2): Core**
1. Smart Search & Filtering
2. In-App Chat
3. Rating & Review System
4. Basic Notifications

**Phase 2 (Months 3-4): Trust**
5. AI Image Recognition
6. Price Discovery & Bidding
7. Pickup Scheduling
8. Enhanced Notifications

**Phase 3 (Months 5-6): Engagement**
9. Saved Searches & Watchlists
10. Seller Analytics Dashboard
11. Quick Actions & Shortcuts

---

## 6. Out of Scope

- Government scheme integration
- Health insurance
- PPE distribution
- Family welfare programs
- Child education
- Women's safety programs
- Worker cooperatives
- Financial inclusion schemes
- Skill development programs
- Environmental impact tracking
- Social programs
- Community organization tools

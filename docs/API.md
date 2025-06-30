# TroupeX API Documentation

## Overview

TroupeX extends the Mastodon API v1 with additional endpoints for custom features. All endpoints follow REST principles and return JSON responses.

## Authentication

Use OAuth2 bearer tokens for API authentication:

```http
Authorization: Bearer YOUR_ACCESS_TOKEN
```

## Custom Endpoints

### Showcase

#### Get Showcase Items
```http
GET /api/v1/accounts/:id/showcase
```

**Response:**
```json
{
  "items": [
    {
      "id": "123",
      "status_id": "456",
      "created_at": "2024-01-01T00:00:00Z",
      "status": { /* Standard status object */ }
    }
  ]
}
```

#### Add to Showcase
```http
POST /api/v1/statuses/:id/showcase
```

#### Remove from Showcase
```http
DELETE /api/v1/statuses/:id/showcase
```

### Messages

#### Get Conversations
```http
GET /api/v1/messages/conversations
```

#### Send Message
```http
POST /api/v1/messages
Content-Type: application/json

{
  "recipient_id": "789",
  "content": "Hello!",
  "media_ids": []
}
```

## Rate Limits

| Endpoint | Limit | Window |
|----------|-------|---------|
| GET endpoints | 300 | 5 minutes |
| POST endpoints | 100 | 5 minutes |
| Media uploads | 30 | 30 minutes |

## Error Handling

```json
{
  "error": "Record not found",
  "error_code": "RECORD_NOT_FOUND",
  "status": 404
}
```

## Webhooks (Coming Soon)

Subscribe to real-time events:
- `status.created`
- `message.received`
- `account.updated`

---

For the complete Mastodon API documentation, see [docs.joinmastodon.org/api/](https://docs.joinmastodon.org/api/)
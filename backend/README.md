# Product Inventory Backend

Node.js backend for a product inventory mobile app using Firebase Firestore.

## Setup

1. Copy `.env.example` to `.env`.
2. Add your Firebase service account JSON in `FIREBASE_SERVICE_ACCOUNT_JSON` or set `GOOGLE_APPLICATION_CREDENTIALS`.
3. Install dependencies:

```bash
cd backend
npm install
```

1. Run locally:

```bash
npm run dev
```

## API Endpoints

- `GET /api/categories`
- `POST /api/categories`
- `GET /api/categories/:id`
- `PUT /api/categories/:id`
- `DELETE /api/categories/:id`

- `GET /api/products`
- `POST /api/products`
- `GET /api/products/:id`
- `PUT /api/products/:id`
- `DELETE /api/products/:id`

- `GET /api/partners`
- `POST /api/partners`
- `GET /api/partners/:id`
- `PUT /api/partners/:id`
- `DELETE /api/partners/:id`

- `GET /api/units`
- `POST /api/units`
- `GET /api/units/:id`
- `PUT /api/units/:id`
- `DELETE /api/units/:id`

- `GET /api/stock-entries`
- `POST /api/stock-entries`
- `GET /api/stock-entries/:id`
- `PUT /api/stock-entries/:id`
- `DELETE /api/stock-entries/:id`

- `GET /api/partner-entries`
- `POST /api/partner-entries`
- `GET /api/partner-entries/:id`
- `DELETE /api/partner-entries/:id`

- `GET /api/stats`
- `POST /api/auth/check`

import { Router } from 'express';
import admin from 'firebase-admin';
import { db } from './firebase.js';

const router = Router();

const serverTimestamp = () => admin.firestore.FieldValue.serverTimestamp();

const parsePagination = (req: any) => ({
  limit: Number(req.query.limit || 20),
  lastId: String(req.query.lastId || ''),
  sortKey: String(req.query.sortKey || 'createdAt'),
  sortDir: (String(req.query.sortDir || 'desc') as 'asc' | 'desc')
});

const toJson = (snapshot: any) => snapshot.docs.map((doc: any) => ({ id: doc.id, ...doc.data() }));

const createEntityRoutes = (name: string, uniqueFields: string[] = []) => {
  const collectionRef = db.collection(name);

  router.get(`/${name}`, async (req, res) => {
    try {
      const search = String(req.query.search || '').trim();
      const { limit, lastId, sortKey, sortDir } = parsePagination(req);
      let q: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = collectionRef;

      if (search) {
        q = q.where('name', '>=', search).where('name', '<=', `${search}\uf8ff`);
      }

      q = q.orderBy(sortKey, sortDir).limit(limit);

      if (lastId) {
        const cursorDoc = await collectionRef.doc(lastId).get();
        if (cursorDoc.exists) {
          q = q.startAfter(cursorDoc);
        }
      }

      const snapshot = await q.get();
      res.json({ data: toJson(snapshot) });
    } catch (error) {
      res.status(500).json({ error: 'Failed to fetch records', details: error instanceof Error ? error.message : null });
    }
  });

  router.post(`/${name}`, async (req, res) => {
    try {
      const data = { ...req.body, createdAt: serverTimestamp(), updatedAt: serverTimestamp() };

      if (uniqueFields.length > 0) {
        const duplicateChecks = await Promise.all(
          uniqueFields.map((field) => collectionRef.where(field, '==', req.body[field]).get())
        );

        if (duplicateChecks.some((snap) => !snap.empty)) {
          return res.status(409).json({ error: `${name} with the same ${uniqueFields.join(' or ')} already exists` });
        }
      }

      const docRef = await collectionRef.add(data);
      const created = await docRef.get();
      res.status(201).json({ id: docRef.id, ...created.data() });
    } catch (error) {
      res.status(500).json({ error: 'Failed to create record', details: error instanceof Error ? error.message : null });
    }
  });

  router.get(`/${name}/:id`, async (req, res) => {
    try {
      const snapshot = await collectionRef.doc(req.params.id).get();
      if (!snapshot.exists) return res.status(404).json({ error: 'Record not found' });
      res.json({ id: snapshot.id, ...snapshot.data() });
    } catch (error) {
      res.status(500).json({ error: 'Failed to fetch record', details: error instanceof Error ? error.message : null });
    }
  });

  router.put(`/${name}/:id`, async (req, res) => {
    try {
      const docRef = collectionRef.doc(req.params.id);
      const snapshot = await docRef.get();
      if (!snapshot.exists) return res.status(404).json({ error: 'Record not found' });

      await docRef.update({ ...req.body, updatedAt: serverTimestamp() });
      const updated = await docRef.get();
      res.json({ id: updated.id, ...updated.data() });
    } catch (error) {
      res.status(500).json({ error: 'Failed to update record', details: error instanceof Error ? error.message : null });
    }
  });

  router.delete(`/${name}/:id`, async (req, res) => {
    try {
      const docRef = collectionRef.doc(req.params.id);
      const snapshot = await docRef.get();
      if (!snapshot.exists) return res.status(404).json({ error: 'Record not found' });

      await docRef.delete();
      res.status(204).end();
    } catch (error) {
      res.status(500).json({ error: 'Failed to delete record', details: error instanceof Error ? error.message : null });
    }
  });
};

createEntityRoutes('categories', ['name', 'slug']);
createEntityRoutes('products', ['sku']);
createEntityRoutes('partners', ['email']);
createEntityRoutes('units', ['name', 'symbol']);

router.post('/auth/check', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ isAdmin: false, error: 'Email is required' });

    const normalizedEmail = String(email).toLowerCase().trim();
    const adminSnapshot = await db.collection('admins').where('email', '==', normalizedEmail).get();

    res.json({ isAdmin: !adminSnapshot.empty });
  } catch (error) {
    res.status(500).json({ error: 'Failed auth check', details: error instanceof Error ? error.message : null });
  }
});

router.get('/stats', async (_req, res) => {
  try {
    const snapshot = await db.collection('system').doc('stats').get();
    res.json(snapshot.exists ? snapshot.data() : {
      totalBuyerEntries: 0,
      totalBuyers: 0,
      totalCategories: 0,
      totalCustomerEntries: 0,
      totalCustomers: 0,
      totalProducts: 0,
      totalStockEntries: 0,
      totalSupplierEntries: 0,
      totalSuppliers: 0
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch stats', details: error instanceof Error ? error.message : null });
  }
});

router.get('/partner-entries', async (req, res) => {
  try {
    const limit = Number(req.query.limit || 20);
    const snapshot = await db.collection('partnerEntries').limit(limit).get();
    res.json({ data: toJson(snapshot) });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch partner entries', details: error instanceof Error ? error.message : null });
  }
});

router.post('/partner-entries', async (req, res) => {
  try {
    const docRef = await db.collection('partnerEntries').add({
      ...req.body,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });
    const snapshot = await docRef.get();
    res.status(201).json({ id: docRef.id, ...snapshot.data() });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create partner entry', details: error instanceof Error ? error.message : null });
  }
});

router.get('/partner-entries/:id', async (req, res) => {
  try {
    const snapshot = await db.collection('partnerEntries').doc(req.params.id).get();
    if (!snapshot.exists) return res.status(404).json({ error: 'Entry not found' });
    res.json({ id: snapshot.id, ...snapshot.data() });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch partner entry', details: error instanceof Error ? error.message : null });
  }
});

router.delete('/partner-entries/:id', async (req, res) => {
  try {
    await db.collection('partnerEntries').doc(req.params.id).delete();
    res.status(204).end();
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete partner entry', details: error instanceof Error ? error.message : null });
  }
});

router.get('/stock-entries', async (req, res) => {
  try {
    const limit = Number(req.query.limit || 20);
    const snapshot = await db.collection('stockEntries').limit(limit).get();
    res.json({ data: toJson(snapshot) });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch stock entries', details: error instanceof Error ? error.message : null });
  }
});

router.post('/stock-entries', async (req, res) => {
  try {
    const docRef = await db.collection('stockEntries').add({
      ...req.body,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });
    const snapshot = await docRef.get();
    res.status(201).json({ id: docRef.id, ...snapshot.data() });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create stock entry', details: error instanceof Error ? error.message : null });
  }
});

router.get('/stock-entries/:id', async (req, res) => {
  try {
    const snapshot = await db.collection('stockEntries').doc(req.params.id).get();
    if (!snapshot.exists) return res.status(404).json({ error: 'Stock entry not found' });
    res.json({ id: snapshot.id, ...snapshot.data() });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch stock entry', details: error instanceof Error ? error.message : null });
  }
});

router.put('/stock-entries/:id', async (req, res) => {
  try {
    const docRef = db.collection('stockEntries').doc(req.params.id);
    const snapshot = await docRef.get();
    if (!snapshot.exists) return res.status(404).json({ error: 'Stock entry not found' });

    await docRef.update({ ...req.body, updatedAt: serverTimestamp() });
    const updated = await docRef.get();
    res.json({ id: updated.id, ...updated.data() });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update stock entry', details: error instanceof Error ? error.message : null });
  }
});

router.delete('/stock-entries/:id', async (req, res) => {
  try {
    await db.collection('stockEntries').doc(req.params.id).delete();
    res.status(204).end();
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete stock entry', details: error instanceof Error ? error.message : null });
  }
});

export default router;

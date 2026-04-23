import { Router, Request, Response } from 'express';
import admin from 'firebase-admin';
import { db } from './firebase.js';

const router = Router();
const productRef = db.collection('products');
const serverTimestamp = () => admin.firestore.FieldValue.serverTimestamp();

const formatProduct = (doc: admin.firestore.DocumentSnapshot) => {
    const data = doc.data();
    if (!data) return null;

    return {
        id: doc.id,
        ...data,
        created_at: data.createdAt?.toDate ? data.createdAt.toDate().toISOString() : data.createdAt,
        stock_quantity: data.stock_quantity || data.stockQuantity,
        compare_price: data.compare_price || data.comparePrice,
    };
};

// --- API ROUTES ---

// GET: Fetch all products (with pagination) OR single product (via ?id= query)
router.get('/products', async (req: Request, res: Response) => {
    try {
        const { id, limit, offset } = req.query;

        if (id && typeof id === 'string') {
            const doc = await productRef.doc(id).get();
            if (!doc.exists) return res.status(404).json({ error: 'Product not found' });
            return res.json(formatProduct(doc));
        }

        // 2. Handle getAllProducts(limit, offset)
        const qLimit = parseInt(limit as string) || 20;
        const qOffset = parseInt(offset as string) || 0;

        const snapshot = await productRef
            .orderBy('createdAt', 'desc')
            .limit(qLimit)
            .offset(qOffset)
            .get();

        const products = snapshot.docs.map(doc => formatProduct(doc));
        
        res.json(products);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

// POST: Add single product
router.post('/products', async (req: Request, res: Response) => {
    try {
        const docRef = productRef.doc();
        
        const data = {
            ...req.body,
            id: docRef.id,
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp()
        };
        
        await docRef.set(data);
        
        const snapshot = await docRef.get();
        res.status(201).json(formatProduct(snapshot));
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

// POST: Bulk Add (addAll)
router.post('/products/bulk', async (req: Request, res: Response) => {
    try {
        const batch = db.batch();
        const productsList = req.body as any[];

        productsList.forEach((item) => {
            const docRef = productRef.doc(); 
            
            batch.set(docRef, {
                ...item,
                id: docRef.id,
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp()
            });
        });

        await batch.commit();
        res.status(201).send();
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

// PUT: Update Product
router.put('/products/:id', async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const docRef = productRef.doc(id);
        
        await docRef.update({
            ...req.body,
            updatedAt: serverTimestamp()
        });

        const updated = await docRef.get();
        res.json(formatProduct(updated));
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

// DELETE: Single Product
router.delete('/products/:id', async (req: Request, res: Response) => {
    try {
        await productRef.doc(req.params.id).delete();
        res.status(204).end();
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

// DELETE: Bulk Delete (deleteAllWithId)
router.delete('/products/bulk', async (req: Request, res: Response) => {
    try {
        const { ids } = req.body as { ids: string[] };
        if (!Array.isArray(ids)) return res.status(400).json({ error: 'IDs must be an array' });

        const batch = db.batch();
        ids.forEach(id => {
            batch.delete(productRef.doc(id));
        });

        await batch.commit();
        res.status(204).end();
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

export default router;
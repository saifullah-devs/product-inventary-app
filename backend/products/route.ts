// src/app/api/products/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { 
  collection, getDocs, query, orderBy, limit as firestoreLimit, 
  startAfter, doc, getDoc, getCountFromServer, where, serverTimestamp, Timestamp, writeBatch, increment 
} from 'firebase/firestore';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const limitParam = parseInt(searchParams.get('limit') || '20');
    const lastId = searchParams.get('lastId');
    const search = searchParams.get('search');
    
    const categoryId = searchParams.get('categoryId');
    const lowStock = searchParams.get('lowStock');
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');

    const sortKey = searchParams.get('sortKey') || 'createdAt';
    const sortDir = (searchParams.get('sortDir') || 'desc') as 'asc' | 'desc';

    const productsRef = collection(db, 'products');
    let q = query(productsRef);

    if (categoryId) q = query(q, where('category', '==', categoryId));
    if (lowStock === 'true') q = query(q, where('isLowStock', '==', true));

    if (startDate) {
      q = query(q, where('createdAt', '>=', Timestamp.fromDate(new Date(startDate))));
    }
    if (endDate) {
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999);
      q = query(q, where('createdAt', '<=', Timestamp.fromDate(end)));
    }
    
    if (search) {
      const searchLower = search.toLowerCase();
      q = query(q, 
        where('nameLower', '>=', searchLower), 
        where('nameLower', '<=', searchLower + '\uf8ff'),
        orderBy('nameLower', 'asc')
      );
    } else {
      q = query(q, orderBy(sortKey, sortDir));
    }

    let totalCount = 0;
    if (!search && !categoryId && lowStock !== 'true' && !startDate && !endDate) {
      const statsDoc = await getDoc(doc(db, 'system', 'stats'));
      if (statsDoc.exists()) {
         totalCount = statsDoc.data().totalProducts || 0;
      } else {
         const countSnap = await getCountFromServer(productsRef);
         totalCount = countSnap.data().count;
      }
    } else {
      const countSnap = await getCountFromServer(q);
      totalCount = countSnap.data().count;
    }

    q = query(q, firestoreLimit(limitParam));

    if (lastId) {
      const lastDocSnap = await getDoc(doc(db, 'products', lastId));
      if (lastDocSnap.exists()) q = query(q, startAfter(lastDocSnap));
    }

    const snapshot = await getDocs(q);
    const products = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || new Date().toISOString(),
    }));

    return NextResponse.json({ products, totalCount, hasMore: products.length === limitParam });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const productsRef = collection(db, 'products');

    const skuQuery = query(productsRef, where('sku', '==', body.sku));
    const skuSnap = await getDocs(skuQuery);
    if (!skuSnap.empty) return NextResponse.json({ error: 'SKU already exists' }, { status: 409 });

    const stock = body.stock || 0;
    const lowStockLimit = body.lowStockLimit || 10;

    const batch = writeBatch(db);
    const newDocRef = doc(productsRef);
    
    batch.set(newDocRef, {
      ...body,
      nameLower: body.name.toLowerCase(),
      skuLower: body.sku.toLowerCase(),
      stock,
      lowStockLimit,
      isLowStock: stock <= lowStockLimit,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });

    // 1. Update Global Stats
    const statsRef = doc(db, 'system', 'stats');
    batch.set(statsRef, { totalProducts: increment(1) }, { merge: true });

    // 2. Increment Category Product Count
    if (body.category) {
      batch.update(doc(db, 'categories', body.category), { productCount: increment(1) });
    }

    // 3. Increment Unit Product Counts (Using Set to prevent double counting if length & width share the same unit)
    const uniqueUnits = [...new Set([body.lengthUnit, body.widthUnit].filter(Boolean))];
    uniqueUnits.forEach(unitId => {
      batch.update(doc(db, 'units', unitId as string), { productCount: increment(1) });
    });

    await batch.commit();

    return NextResponse.json({ success: true, id: newDocRef.id });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
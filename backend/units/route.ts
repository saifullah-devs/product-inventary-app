// src/app/api/units/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { 
  collection, getDocs, query, orderBy, limit as firestoreLimit, 
  startAfter, doc, getDoc, getCountFromServer, where, serverTimestamp, writeBatch, increment 
} from 'firebase/firestore';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const limitParam = parseInt(searchParams.get('limit') || '20');
    const lastId = searchParams.get('lastId');
    const search = searchParams.get('search');
    const sortKey = searchParams.get('sortKey') || 'createdAt';
    const sortDir = (searchParams.get('sortDir') || 'desc') as 'asc' | 'desc';

    const unitsRef = collection(db, 'units');
    let q = query(unitsRef);

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
    if (!search) {
      const statsDoc = await getDoc(doc(db, 'system', 'stats'));
      if (statsDoc.exists()) {
         totalCount = statsDoc.data().totalUnits || 0;
      } else {
         const countSnap = await getCountFromServer(unitsRef);
         totalCount = countSnap.data().count;
      }
    } else {
      const countSnap = await getCountFromServer(q);
      totalCount = countSnap.data().count;
    }

    q = query(q, firestoreLimit(limitParam));

    if (lastId) {
      const lastDocSnap = await getDoc(doc(db, 'units', lastId));
      if (lastDocSnap.exists()) {
        q = query(q, startAfter(lastDocSnap));
      }
    }

    const snapshot = await getDocs(q);
    
    // Now we map the productCount directly! No expensive sub-queries.
    const units = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      productCount: doc.data().productCount || 0,
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || new Date().toISOString(),
    }));

    return NextResponse.json({ units, totalCount, hasMore: units.length === limitParam });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { name, symbol, description, type } = body;
    const unitsRef = collection(db, 'units');

    const nameQuery = query(unitsRef, where('name', '==', name));
    const symbolQuery = query(unitsRef, where('symbol', '==', symbol));
    
    const [nameSnap, symbolSnap] = await Promise.all([getDocs(nameQuery), getDocs(symbolQuery)]);
    
    if (!nameSnap.empty) return NextResponse.json({ error: 'Unit name already exists' }, { status: 409 });
    if (!symbolSnap.empty) return NextResponse.json({ error: 'Unit symbol already exists' }, { status: 409 });

    const batch = writeBatch(db);
    const newDocRef = doc(unitsRef);
    batch.set(newDocRef, {
      name,
      nameLower: name.toLowerCase(),
      symbol,
      description: description || '',
      type: type || 'length',
      productCount: 0, // Establish field
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });

    const statsRef = doc(db, 'system', 'stats');
    batch.set(statsRef, { totalUnits: increment(1) }, { merge: true });

    await batch.commit();

    return NextResponse.json({ success: true, id: newDocRef.id });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
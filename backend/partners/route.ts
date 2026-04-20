// src/app/api/partners/route.ts
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
    const typeFilter = searchParams.get('type');
    const sortKey = searchParams.get('sortKey') || 'createdAt';
    const sortDir = (searchParams.get('sortDir') || 'desc') as 'asc' | 'desc';

    const partnersRef = collection(db, 'partners');
    let q = query(partnersRef);

    if (typeFilter && typeFilter !== 'all') {
      q = query(q, where('type', '==', typeFilter));
    }

    if (search) {
      const searchLower = search.toLowerCase();
      q = query(q, 
        where('nameLower', '>=', searchLower), 
        where('nameLower', '<=', searchLower + '\uf8ff')
      );
    }
    
    if (search) {
      q = query(q, orderBy('nameLower', 'asc'));
    } else {
      q = query(q, orderBy(sortKey, sortDir));
    }

    let totalCount = 0;
      const statsDoc = await getDoc(doc(db, 'system', 'stats'));
      if (statsDoc.exists()) {
        const stats = statsDoc.data();
        if (typeFilter === 'customer') totalCount = stats.totalCustomers || 0;
        else if (typeFilter === 'buyer') totalCount = stats.totalBuyers || 0;
        else if (typeFilter === 'supplier') totalCount = stats.totalSuppliers || 0;
        else totalCount = (stats.totalCustomers || 0) + (stats.totalBuyers || 0) + (stats.totalSuppliers || 0);
      } else {
        const countSnap = await getCountFromServer(partnersRef);
        totalCount = countSnap.data().count;
      }

    q = query(q, firestoreLimit(limitParam));

    if (lastId) {
      const lastDocSnap = await getDoc(doc(db, 'partners', lastId));
      if (lastDocSnap.exists()) {
        q = query(q, startAfter(lastDocSnap));
      }
    }

    const snapshot = await getDocs(q);
    const partners = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || new Date().toISOString(),
    }));

    return NextResponse.json({ partners, totalCount, hasMore: partners.length === limitParam });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { name, email, phone, address, type, netBalance } = body;
    const partnersRef = collection(db, 'partners');

    if (email) {
      const emailQuery = query(partnersRef, where('email', '==', email));
      const emailSnap = await getDocs(emailQuery);
      if (!emailSnap.empty) return NextResponse.json({ error: 'Email address already exists' }, { status: 409 });
    }

    if (phone) {
      const phoneQuery = query(partnersRef, where('phone', '==', phone));
      const phoneSnap = await getDocs(phoneQuery);
      if (!phoneSnap.empty) return NextResponse.json({ error: 'Phone number already exists' }, { status: 409 });
    }

    const batch = writeBatch(db);
    const newDocRef = doc(partnersRef);
    
    batch.set(newDocRef, {
      name, 
      nameLower: name.toLowerCase(), 
      email: email || '', 
      phone: phone || '', 
      address: address || '',
      type: type || 'customer',
      totalSales: 0,
      totalPurchases: 0,
      netBalance: netBalance || 0, // Set initial balance
      ordersCount: 0, 
      createdAt: serverTimestamp(), 
      updatedAt: serverTimestamp()
    });

    const statsRef = doc(db, 'system', 'stats');
    const statsField = `total${(type || 'customer').charAt(0).toUpperCase() + (type || 'customer').slice(1)}s`;
    batch.set(statsRef, { [statsField]: increment(1) }, { merge: true });

    await batch.commit();

    return NextResponse.json({ success: true, id: newDocRef.id });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
// src\app\api\categories\route.ts
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

    const categoriesRef = collection(db, 'categories');

    let q = query(categoriesRef);

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
    const statsDoc = await getDoc(doc(db, 'system', 'stats'));
    if (statsDoc.exists()) {
      totalCount = statsDoc.data().totalCategories || 0;
    } else {
      const countSnap = await getCountFromServer(categoriesRef);
      totalCount = countSnap.data().count;
    }

    q = query(q, firestoreLimit(limitParam));

    if (lastId) {
      const lastDocSnap = await getDoc(doc(db, 'categories', lastId));
      if (lastDocSnap.exists()) {
        q = query(q, startAfter(lastDocSnap));
      }
    }

    const snapshot = await getDocs(q);
    const categories = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || new Date().toISOString(),
    }));

    return NextResponse.json({ categories, totalCount, hasMore: categories.length === limitParam });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { name, slug, description } = body;
    const categoriesRef = collection(db, 'categories');

    const nameQuery = query(categoriesRef, where('name', '==', name));
    const slugQuery = query(categoriesRef, where('slug', '==', slug));

    const [nameSnap, slugSnap] = await Promise.all([getDocs(nameQuery), getDocs(slugQuery)]);

    if (!nameSnap.empty) return NextResponse.json({ error: 'Category name already exists' }, { status: 409 });
    if (!slugSnap.empty) return NextResponse.json({ error: 'Category slug already exists' }, { status: 409 });

    const categoryData: any = {
      name,
      nameLower: name.toLowerCase(),
      slug,
      description: description || '',
      productCount: 0,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    };

    const batch = writeBatch(db);
    const newDocRef = doc(categoriesRef);
    batch.set(newDocRef, categoryData);

    const statsRef = doc(db, 'system', 'stats');
    batch.set(statsRef, { totalCategories: increment(1) }, { merge: true });

    await batch.commit();

    return NextResponse.json({ success: true, id: newDocRef.id });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
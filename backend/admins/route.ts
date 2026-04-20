// src/app/api/admins/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { 
  collection, 
  getDocs, 
  addDoc, 
  query, 
  where, 
  orderBy,
  serverTimestamp,
  getCountFromServer,
  limit as firestoreLimit,
  startAfter,
  doc,
  getDoc
} from 'firebase/firestore';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const limitParam = parseInt(searchParams.get('limit') || '20');
    const lastId = searchParams.get('lastId');
    const search = searchParams.get('search');
    const sortKey = searchParams.get('sortKey') || 'createdAt';
    const sortDir = (searchParams.get('sortDir') || 'desc') as 'asc' | 'desc';

    const adminsRef = collection(db, 'admins');
    let q = query(adminsRef);

    if (search) {
      const searchLower = search.toLowerCase();
      q = query(q, 
        where('email', '>=', searchLower), 
        where('email', '<=', searchLower + '\uf8ff'),
        orderBy('email', 'asc')
      );
    } else {
      q = query(q, orderBy(sortKey, sortDir));
    }

    const countSnap = await getCountFromServer(q);
    const totalCount = countSnap.data().count;

    q = query(q, firestoreLimit(limitParam));

    if (lastId) {
      const lastDocSnap = await getDoc(doc(db, 'admins', lastId));
      if (lastDocSnap.exists()) {
        q = query(q, startAfter(lastDocSnap));
      }
    }

    const snapshot = await getDocs(q);
    const admins = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || new Date().toISOString(),
    }));

    return NextResponse.json({ admins, totalCount, hasMore: admins.length === limitParam });

  } catch (error: any) {
    console.error('Error fetching admins:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { email, name } = body;

    if (!email) {
      return NextResponse.json({ error: 'Email is required' }, { status: 400 });
    }

    const normalizedEmail = email.toLowerCase().trim();

    // 1. Check Duplicates in Env
    const whitelistedEmails = process.env.ADMIN_EMAIL_WHITELIST?.split(',') || [];
    if (whitelistedEmails.some(e => e.toLowerCase().trim() === normalizedEmail)) {
      return NextResponse.json({ error: 'This user is already a Super Admin via system environment' }, { status: 409 });
    }

    // 2. Check Duplicates in DB
    const adminsRef = collection(db, 'admins');
    const q = query(adminsRef, where('email', '==', normalizedEmail));
    const snapshot = await getDocs(q);

    if (!snapshot.empty) {
      return NextResponse.json({ error: 'An admin with this email already exists' }, { status: 409 });
    }

    // 3. Create
    const newAdmin = {
      name: name || normalizedEmail.split('@')[0],
      email: normalizedEmail,
      role: 'admin',
      isFromEnv: false,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };

    const docRef = await addDoc(adminsRef, newAdmin);

    return NextResponse.json({ 
      success: true, 
      id: docRef.id, 
      message: 'Admin created successfully!' 
    }, { status: 201 });

  } catch (error: any) {
    console.error('Error creating admin:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
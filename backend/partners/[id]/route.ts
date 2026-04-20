// src/app/api/partners/[id]/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { doc, getDoc, updateDoc, collection, query, where, getDocs, serverTimestamp, writeBatch, increment } from 'firebase/firestore';

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const body = await request.json();
    const { name, email, phone, address, type, netBalance } = body;
    const partnersRef = collection(db, 'partners');

    const docRef = doc(db, 'partners', id);
    const oldSnap = await getDoc(docRef);
    if (!oldSnap.exists()) return NextResponse.json({ error: 'Partner not found' }, { status: 404 });
    const oldData = oldSnap.data();

    if (email) {
      const emailQuery = query(partnersRef, where('email', '==', email));
      const emailSnap = await getDocs(emailQuery);
      if (emailSnap.docs.some(d => d.id !== id)) return NextResponse.json({ error: 'Email address already exists' }, { status: 409 });
    }

    if (phone) {
      const phoneQuery = query(partnersRef, where('phone', '==', phone));
      const phoneSnap = await getDocs(phoneQuery);
      if (phoneSnap.docs.some(d => d.id !== id)) return NextResponse.json({ error: 'Phone number already exists' }, { status: 409 });
    }

    const batch = writeBatch(db);

    batch.update(docRef, { 
      name, 
      nameLower: name.toLowerCase(), 
      email: email || '', 
      phone: phone || '', 
      address: address || '', 
      type,
      netBalance: netBalance || 0, // Update balance explicitly
      updatedAt: serverTimestamp() 
    });

    if (oldData.type !== type) {
      const statsRef = doc(db, 'system', 'stats');
      const oldStatsField = `total${oldData.type.charAt(0).toUpperCase() + oldData.type.slice(1)}s`;
      const newStatsField = `total${type.charAt(0).toUpperCase() + type.slice(1)}s`;
      batch.set(statsRef, {
        [oldStatsField]: increment(-1),
        [newStatsField]: increment(1)
      }, { merge: true });
    }

    await batch.commit();

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const docRef = doc(db, 'partners', id);
    const docSnap = await getDoc(docRef);

    if (!docSnap.exists()) return NextResponse.json({ error: 'Partner not found' }, { status: 404 });
    const data = docSnap.data();
    if (data.ordersCount > 0) return NextResponse.json({ error: 'Cannot delete partner with existing orders' }, { status: 400 });

    const batch = writeBatch(db);
    batch.delete(docRef);
    
    const statsRef = doc(db, 'system', 'stats');
    const statsField = `total${data.type.charAt(0).toUpperCase() + data.type.slice(1)}s`;
    batch.set(statsRef, { [statsField]: increment(-1) }, { merge: true });

    await batch.commit();

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
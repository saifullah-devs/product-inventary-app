// src/app/api/units/[id]/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { doc, getDoc, updateDoc, collection, query, where, getDocs, serverTimestamp, writeBatch, increment } from 'firebase/firestore';

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const body = await request.json();
    const { name, symbol, description, type } = body;
    const unitsRef = collection(db, 'units');

    const nameQuery = query(unitsRef, where('name', '==', name));
    const symbolQuery = query(unitsRef, where('symbol', '==', symbol));

    const [nameSnap, symbolSnap] = await Promise.all([getDocs(nameQuery), getDocs(symbolQuery)]);

    if (nameSnap.docs.some(d => d.id !== id)) return NextResponse.json({ error: 'Unit name already exists' }, { status: 409 });
    if (symbolSnap.docs.some(d => d.id !== id)) return NextResponse.json({ error: 'Unit symbol already exists' }, { status: 409 });

    const docRef = doc(db, 'units', id);
    await updateDoc(docRef, { 
      name, 
      nameLower: name.toLowerCase(),
      symbol, 
      description: description || '', 
      type: type || 'length',
      updatedAt: serverTimestamp() 
    });

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const docRef = doc(db, 'units', id);
    
    // Read the internal count instead of querying all products
    const unitSnap = await getDoc(docRef);
    if (!unitSnap.exists()) return NextResponse.json({ error: 'Unit not found' }, { status: 404 });
    
    if (unitSnap.data().productCount > 0) {
      return NextResponse.json({ error: 'Cannot delete unit that is being used by products' }, { status: 400 });
    }

    const batch = writeBatch(db);
    batch.delete(docRef);
    
    const statsRef = doc(db, 'system', 'stats');
    batch.set(statsRef, { totalUnits: increment(-1) }, { merge: true });
    
    await batch.commit();
    
    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
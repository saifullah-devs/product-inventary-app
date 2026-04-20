// src/app/api/products/[id]/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { doc, getDoc, collection, query, where, getDocs, serverTimestamp, writeBatch, increment } from 'firebase/firestore';

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const body = await request.json();
    const productsRef = collection(db, 'products');

    const skuQuery = query(productsRef, where('sku', '==', body.sku));
    const skuSnap = await getDocs(skuQuery);
    if (skuSnap.docs.some(d => d.id !== id)) return NextResponse.json({ error: 'SKU already exists' }, { status: 409 });

    const docRef = doc(db, 'products', id);
    const oldSnap = await getDoc(docRef);
    
    if (!oldSnap.exists()) return NextResponse.json({ error: 'Product not found' }, { status: 404 });
    const oldData = oldSnap.data();

    const stock = body.stock || 0;
    const lowStockLimit = body.lowStockLimit || 10;

    const batch = writeBatch(db);

    batch.update(docRef, { 
      ...body,
      nameLower: body.name.toLowerCase(),
      skuLower: body.sku.toLowerCase(),
      isLowStock: stock <= lowStockLimit,
      updatedAt: serverTimestamp() 
    });

    // 1. Handle Category Changes
    if (oldData.category !== body.category) {
      if (oldData.category) batch.update(doc(db, 'categories', oldData.category), { productCount: increment(-1) });
      if (body.category) batch.update(doc(db, 'categories', body.category), { productCount: increment(1) });
    }

    // 2. Handle Unit Changes
    const oldUnits = [...new Set([oldData.lengthUnit, oldData.widthUnit].filter(Boolean))];
    const newUnits = [...new Set([body.lengthUnit, body.widthUnit].filter(Boolean))];
    
    const unitsToRemove = oldUnits.filter(u => !newUnits.includes(u));
    const unitsToAdd = newUnits.filter(u => !oldUnits.includes(u));

    unitsToRemove.forEach(unitId => batch.update(doc(db, 'units', unitId as string), { productCount: increment(-1) }));
    unitsToAdd.forEach(unitId => batch.update(doc(db, 'units', unitId as string), { productCount: increment(1) }));

    await batch.commit();

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const docRef = doc(db, 'products', id);
    const oldSnap = await getDoc(docRef);

    if (!oldSnap.exists()) return NextResponse.json({ error: 'Product not found' }, { status: 404 });
    const oldData = oldSnap.data();

    const batch = writeBatch(db);
    batch.delete(docRef);
    
    // 1. Update Global Stats
    const statsRef = doc(db, 'system', 'stats');
    batch.set(statsRef, { totalProducts: increment(-1) }, { merge: true });
    
    // 2. Decrement Category Count
    if (oldData.category) {
      batch.update(doc(db, 'categories', oldData.category), { productCount: increment(-1) });
    }

    // 3. Decrement Unit Counts
    const uniqueUnits = [...new Set([oldData.lengthUnit, oldData.widthUnit].filter(Boolean))];
    uniqueUnits.forEach(unitId => {
      batch.update(doc(db, 'units', unitId as string), { productCount: increment(-1) });
    });

    await batch.commit();
    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
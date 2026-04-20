// src\app\api\categories\[id]\route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { doc, getDoc, updateDoc, collection, query, where, getDocs, serverTimestamp, writeBatch, increment } from 'firebase/firestore';

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const body = await request.json();
    const { name, slug, description } = body;
    const categoriesRef = collection(db, 'categories');

    const nameQuery = query(categoriesRef, where('name', '==', name));
    const slugQuery = query(categoriesRef, where('slug', '==', slug));

    const [nameSnap, slugSnap] = await Promise.all([getDocs(nameQuery), getDocs(slugQuery)]);

    const isDuplicateName = nameSnap.docs.some(d => d.id !== id);
    const isDuplicateSlug = slugSnap.docs.some(d => d.id !== id);

    if (isDuplicateName) return NextResponse.json({ error: 'Category name already exists' }, { status: 409 });
    if (isDuplicateSlug) return NextResponse.json({ error: 'Category slug already exists' }, { status: 409 });

    const docRef = doc(db, 'categories', id);

    await updateDoc(docRef, {
      name,
      nameLower: name.toLowerCase(),
      slug,
      description: description || '',
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
    const docRef = doc(db, 'categories', id);
    const docSnap = await getDoc(docRef);

    if (!docSnap.exists()) return NextResponse.json({ error: 'Category not found' }, { status: 404 });

    if (docSnap.data().productCount > 0) {
      return NextResponse.json({ error: 'Cannot delete category with existing products' }, { status: 400 });
    }

    const batch = writeBatch(db);
    batch.delete(docRef);

    const statsRef = doc(db, 'system', 'stats');
    batch.set(statsRef, { totalCategories: increment(-1) }, { merge: true });

    await batch.commit();

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
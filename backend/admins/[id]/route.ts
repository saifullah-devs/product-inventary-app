// src/app/api/admins/[id]/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { doc, getDoc, updateDoc, deleteDoc, collection, query, where, getDocs, serverTimestamp } from 'firebase/firestore';

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const body = await request.json();
    const { email, name } = body;
    const adminsRef = collection(db, 'admins');

    const docRef = doc(db, 'admins', id);
    const oldSnap = await getDoc(docRef);
    if (!oldSnap.exists()) return NextResponse.json({ error: 'Admin not found' }, { status: 404 });

    const normalizedEmail = email.toLowerCase().trim();

    if (normalizedEmail) {
      const emailQuery = query(adminsRef, where('email', '==', normalizedEmail));
      const emailSnap = await getDocs(emailQuery);
      if (emailSnap.docs.some(d => d.id !== id)) return NextResponse.json({ error: 'Email address already exists for another admin' }, { status: 409 });
    }

    await updateDoc(docRef, { 
      name: name || normalizedEmail.split('@')[0], 
      email: normalizedEmail,
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
    const docRef = doc(db, 'admins', id);
    const docSnap = await getDoc(docRef);

    if (!docSnap.exists()) return NextResponse.json({ error: 'Admin not found' }, { status: 404 });

    await deleteDoc(docRef);
    
    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
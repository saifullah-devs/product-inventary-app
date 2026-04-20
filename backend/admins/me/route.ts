// src/app/api/admins/me/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { collection, query, where, getDocs, addDoc, updateDoc, doc, serverTimestamp } from 'firebase/firestore';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const email = searchParams.get('email');

    if (!email) {
      return NextResponse.json({ error: 'Email is required' }, { status: 400 });
    }

    const normalizedEmail = email.toLowerCase().trim();

    // 1. Check Environment Super Admins first (Fastest)
    const envAdmins = process.env.ADMIN_EMAIL_WHITELIST?.split(',') || [];
    const isEnvSuperAdmin = envAdmins.some(e => e.trim().toLowerCase() === normalizedEmail);

    if (isEnvSuperAdmin) {
      const adminsRef = collection(db, 'admins');
      const q = query(adminsRef, where('email', '==', normalizedEmail));
      const querySnapshot = await getDocs(q);

      let adminId = '';
      let adminName = 'System Admin';

      // Auto-Sync logic: If they are in .env but NOT in DB, add them automatically.
      if (querySnapshot.empty) {
        const newDoc = await addDoc(adminsRef, {
          email: normalizedEmail,
          name: normalizedEmail.split('@')[0],
          role: 'super',
          isFromEnv: true,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        });
        adminId = newDoc.id;
        adminName = normalizedEmail.split('@')[0];
      } else {
        // If they already exist, just ensure their role and env flag is strictly enforced
        adminId = querySnapshot.docs[0].id;
        const docData = querySnapshot.docs[0].data();
        adminName = docData.name || 'System Admin';
        
        if (docData.role !== 'super' || !docData.isFromEnv) {
           await updateDoc(doc(db, 'admins', adminId), {
             role: 'super',
             isFromEnv: true,
             updatedAt: serverTimestamp()
           });
        }
      }

      return NextResponse.json({
        id: adminId,
        role: 'super',
        email: normalizedEmail,
        name: adminName,
        isFromEnv: true
      });
    }

    // 2. Check Database for Sub-Admin Record
    const adminsRef = collection(db, 'admins');
    const q = query(adminsRef, where('email', '==', normalizedEmail));
    const querySnapshot = await getDocs(q);

    if (querySnapshot.empty) {
      return NextResponse.json({ error: 'Admin not found' }, { status: 404 });
    }

    const adminDoc = querySnapshot.docs[0];
    const adminData = adminDoc.data();

    return NextResponse.json({
      id: adminDoc.id,
      ...adminData,
      role: adminData.role || 'admin' 
    });

  } catch (error) {
    console.error('Error fetching admin data:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
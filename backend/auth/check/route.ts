import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';

export async function POST(request: NextRequest) {
  try {
    const { email } = await request.json();

    if (!email) {
      return NextResponse.json({ isAdmin: false }, { status: 400 });
    }

    const normalizedEmail = email.toLowerCase().trim();

    // 1. Check whitelisted emails from environment variable first (Super Admins)
    const whitelistedEmails = process.env.ADMIN_EMAIL_WHITELIST?.split(',') || [];
    const isEnvAdmin = whitelistedEmails.some(whitelistedEmail => 
      whitelistedEmail.toLowerCase().trim() === normalizedEmail
    );

    if (isEnvAdmin) {
      return NextResponse.json({ isAdmin: true, role: 'super' });
    }

    // 2. If not in env, check the database for authorized admins
    const adminsRef = collection(db, 'admins');
    const q = query(adminsRef, where('email', '==', normalizedEmail));
    const querySnapshot = await getDocs(q);

    if (!querySnapshot.empty) {
      return NextResponse.json({ isAdmin: true, role: 'admin' });
    }

    // 3. If neither, deny access
    return NextResponse.json({ isAdmin: false });
  } catch (error) {
    console.error('Error checking admin status:', error);
    return NextResponse.json({ isAdmin: false }, { status: 500 });
  }
}
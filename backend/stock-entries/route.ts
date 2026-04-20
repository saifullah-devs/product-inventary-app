// src/app/api/stock-entries/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import {
  collection, getDocs, query, orderBy, limit as firestoreLimit,
  startAfter, doc, getDoc, getCountFromServer, where, serverTimestamp, runTransaction, Timestamp, increment
} from 'firebase/firestore';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const limitParam = parseInt(searchParams.get('limit') || '20');
    const lastId = searchParams.get('lastId');
    const search = searchParams.get('search');

    const type = searchParams.get('type');
    const productId = searchParams.get('productId');
    const customerId = searchParams.get('customerId');
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');

    const entriesRef = collection(db, 'stockEntries');
    let q = query(entriesRef);

    if (type && type !== 'all') q = query(q, where('type', '==', type));
    if (productId) q = query(q, where('productId', '==', productId));
    if (customerId) q = query(q, where('customerId', '==', customerId));

    if (startDate) {
      q = query(q, where('date', '>=', Timestamp.fromDate(new Date(startDate))));
    }
    if (endDate) {
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999);
      q = query(q, where('date', '<=', Timestamp.fromDate(end)));
    }

    if (search) {
      const searchLower = search.toLowerCase();
      q = query(q,
        where('productNameLower', '>=', searchLower),
        where('productNameLower', '<=', searchLower + '\uf8ff')
      );
    }

    if (search) q = query(q, orderBy('productNameLower', 'asc'));
    if (startDate || endDate) q = query(q, orderBy('date', 'desc'));
    if (!search && !startDate && !endDate) q = query(q, orderBy('date', 'desc'));

    // ALWAYS get overall stats directly from metadata
    let totalCount = 0;
    const statsDoc = await getDoc(doc(db, 'system', 'stats'));
    if (statsDoc.exists()) {
      totalCount = statsDoc.data().totalStockEntries || 0;
    } else {
      const countSnap = await getCountFromServer(entriesRef);
      totalCount = countSnap.data().count;
    }

    q = query(q, firestoreLimit(limitParam));

    if (lastId) {
      const lastDocSnap = await getDoc(doc(db, 'stockEntries', lastId));
      if (lastDocSnap.exists()) q = query(q, startAfter(lastDocSnap));
    }

    const snapshot = await getDocs(q);
    const entries = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      date: doc.data().date?.toDate?.()?.toISOString() || new Date().toISOString(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || new Date().toISOString(),
    }));

    return NextResponse.json({ entries, totalCount, hasMore: entries.length === limitParam });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const entryData = await request.json();

    const entryId = await runTransaction(db, async (transaction) => {
      // ==========================================
      // PHASE 1: ALL READS
      // ==========================================
      const productRef = doc(db, 'products', entryData.productId);
      const productDoc = await transaction.get(productRef);
      if (!productDoc.exists()) throw new Error('Product not found');

      // Robust check for optional customer
      const hasCustomer = entryData.customerId && String(entryData.customerId).trim() !== '';
      let partnerDoc = null;
      let partnerRef: any = null;

      if (hasCustomer) {
        partnerRef = doc(db, 'partners', entryData.customerId);
        partnerDoc = await transaction.get(partnerRef);
        if (!partnerDoc.exists()) throw new Error('Selected Partner not found');
      }

      // ==========================================
      // PHASE 2: CALCULATIONS & VALIDATIONS
      // ==========================================

      // 1. Product Math
      const product = productDoc.data();
      const currentStock = product.stock || 0;
      const lowStockLimit = product.lowStockLimit || 10;

      let newStock;
      if (entryData.type === 'in') {
        newStock = currentStock + entryData.quantity;
      } else if (entryData.type === 'out') {
        if (currentStock < entryData.quantity) {
          throw new Error(`Insufficient stock. Available: ${currentStock}, Requested: ${entryData.quantity}`);
        }
        newStock = currentStock - entryData.quantity;
      } else {
        throw new Error('Invalid entry type. Must be "in" or "out"');
      }
      const isLowStock = newStock <= lowStockLimit;

      // 2. Partner Math (Only applies on 'out' / Sales if a customer is selected)
      let partnerUpdate = null;
      if (partnerDoc && entryData.type === 'out') {
        const partner = partnerDoc.data() as any;

        if (partner.type === 'supplier') {
          throw new Error('You cannot register an outbound sale to a supplier. Please select a Customer or Buyer.');
        }

        let newBalance = partner.netBalance || 0;
        let newSales = partner.totalSales || 0;

        const entryAmount = Number(entryData.totalPrice || entryData.amount || (entryData.price ? entryData.price * entryData.quantity : 0)) || 0;

        newBalance += entryAmount;
        newSales += entryAmount;

        partnerUpdate = {
          netBalance: newBalance,
          totalSales: newSales,
          updatedAt: serverTimestamp()
        };
      }

      // ==========================================
      // PHASE 3: ALL WRITES
      // ==========================================

      // Update Product
      transaction.update(productRef, {
        stock: newStock,
        isLowStock: isLowStock,
        updatedAt: serverTimestamp()
      });

      // Update Partner (Only if we created an update payload)
      if (partnerRef && partnerUpdate) {
        transaction.update(partnerRef, partnerUpdate);
      }

      // Create Entry (Clean up payload to not store empty strings for customerId)
      const cleanEntryData = { ...entryData };
      if (!hasCustomer) {
        delete cleanEntryData.customerId;
        delete cleanEntryData.customerName;
      }

      const entriesRef = collection(db, 'stockEntries');
      const entryDocRef = doc(entriesRef);

      const newEntry = {
        ...cleanEntryData,
        productNameLower: (entryData.productName || '').toLowerCase(),
        date: Timestamp.fromDate(new Date(entryData.date)),
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      };

      transaction.set(entryDocRef, newEntry);

      // Update Stats
      const statsRef = doc(db, 'system', 'stats');
      transaction.set(statsRef, { totalStockEntries: increment(1) }, { merge: true });

      return entryDocRef.id;
    });

    return NextResponse.json({ success: true, id: entryId });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
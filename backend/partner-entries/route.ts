// src/app/api/partner-entries/route.ts
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

    // Filters
    const type = searchParams.get('type'); // 'in' or 'out'
    const partnerType = searchParams.get('partnerType'); // 'customer', 'buyer', 'supplier'
    const partnerId = searchParams.get('partnerId');
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');

    const entriesRef = collection(db, 'partnerEntries');
    let q = query(entriesRef);

    // Apply exact equality filters
    if (type && type !== 'all') q = query(q, where('type', '==', type));
    if (partnerType && partnerType !== 'all') q = query(q, where('partnerType', '==', partnerType));
    if (partnerId) q = query(q, where('partnerId', '==', partnerId));

    // Apply date range filters
    if (startDate) {
      q = query(q, where('date', '>=', Timestamp.fromDate(new Date(startDate))));
    }
    if (endDate) {
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999);
      q = query(q, where('date', '<=', Timestamp.fromDate(end)));
    }

    // Apply prefix search filter
    if (search) {
      const searchLower = search.toLowerCase();
      q = query(q,
        where('partnerNameLower', '>=', searchLower),
        where('partnerNameLower', '<=', searchLower + '\uf8ff')
      );
    }

    if (search) q = query(q, orderBy('partnerNameLower', 'asc'));
    if (startDate || endDate) q = query(q, orderBy('date', 'desc'));
    if (!search && !startDate && !endDate) q = query(q, orderBy('date', 'desc'));

    let totalCount = 0;
    const statsDoc = await getDoc(doc(db, 'system', 'stats'));
    if (statsDoc.exists()) {
      const stats = statsDoc.data();
      if (partnerType === 'customer') totalCount = stats.totalCustomerEntries || 0;
      else if (partnerType === 'buyer') totalCount = stats.totalBuyerEntries || 0;
      else if (partnerType === 'supplier') totalCount = stats.totalSupplierEntries || 0;
      else totalCount = (stats.totalCustomerEntries || 0) + (stats.totalBuyerEntries || 0) + (stats.totalSupplierEntries || 0);
    } else {
      const countSnap = await getCountFromServer(entriesRef);
      totalCount = countSnap.data().count;
    }

    q = query(q, firestoreLimit(limitParam));

    if (lastId) {
      const lastDocSnap = await getDoc(doc(db, 'partnerEntries', lastId));
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
      // PHASE 1: ALL READS (Must happen first)
      // ==========================================

      const partnerRef = doc(db, 'partners', entryData.partnerId);
      const partnerDoc = await transaction.get(partnerRef);

      if (!partnerDoc.exists()) throw new Error('Partner not found');

      // We use a Map to safely store all the read product documents
      const productDocsMap = new Map();
      if (entryData.entryMethod === 'bill' && entryData.items && entryData.items.length > 0) {
        for (const item of entryData.items) {
          const productRef = doc(db, 'products', item.productId);
          const productDoc = await transaction.get(productRef);
          if (!productDoc.exists()) throw new Error(`Product ${item.name} not found`);
          productDocsMap.set(item.productId, { ref: productRef, data: productDoc.data() });
        }
      }

      // ==========================================
      // PHASE 2: CALCULATIONS & VALIDATIONS
      // ==========================================

      const partner = partnerDoc.data();
      const currentBalance = partner.netBalance || 0;
      const currentSales = partner.totalSales || 0;
      const currentPurchases = partner.totalPurchases || 0;

      let newBalance = currentBalance;
      let newSales = currentSales;
      let newPurchases = currentPurchases;

      if (entryData.type === 'in') {
        newBalance -= entryData.amount;
        newPurchases += entryData.amount; // Every "in" adds to purchases
      } else if (entryData.type === 'out') {
        newBalance += entryData.amount;
        newSales += entryData.amount; // Every "out" adds to sales
      } else {
        throw new Error('Invalid entry type. Must be "in" or "out"');
      }

      // Calculate Stock Updates in memory (Only if it's a bill)
      const productUpdates = [];
      if (entryData.entryMethod === 'bill' && entryData.items && entryData.items.length > 0) {
        for (const item of entryData.items) {
          const { ref, data: productData } = productDocsMap.get(item.productId);
          const currentStock = productData.stock || 0;
          const lowStockLimit = productData.lowStockLimit || 10; // Extract limit
          let newStock = currentStock;

          if (entryData.type === 'out') {
            // We are selling to a customer -> stock goes DOWN
            if (currentStock < item.quantity) {
              throw new Error(`Insufficient stock for ${item.name}. Available: ${currentStock}, Requested: ${item.quantity}`);
            }
            newStock = currentStock - item.quantity;
          } else if (entryData.type === 'in') {
            // We are purchasing from a supplier -> stock goes UP
            newStock = currentStock + item.quantity;
          }

          // Calculate new boolean based on limit
          const isLowStock = newStock <= lowStockLimit;

          // Store the planned update
          productUpdates.push({ ref, newStock, isLowStock });
        }
      }

      // ==========================================
      // PHASE 3: ALL WRITES
      // ==========================================

      // 1. Write Product Updates
      for (const update of productUpdates) {
        transaction.update(update.ref, {
          stock: update.newStock,
          isLowStock: update.isLowStock, // FIX: Inject the boolean
          updatedAt: serverTimestamp()
        });
      }

      // 2. Write Partner Updates
      transaction.update(partnerRef, {
        netBalance: newBalance,
        totalSales: newSales,
        totalPurchases: newPurchases,
        updatedAt: serverTimestamp()
      });

      // 3. Write Ledger Entry
      const entriesRef = collection(db, 'partnerEntries');
      const entryDocRef = doc(entriesRef);

      const newEntry = {
        partnerId: entryData.partnerId,
        partnerName: partner.name,
        partnerNameLower: (partner.name || '').toLowerCase(),
        partnerType: partner.type, // 'customer', 'buyer', 'supplier'
        type: entryData.type,
        amount: entryData.amount,
        entryMethod: entryData.entryMethod || 'manual',
        items: entryData.items || [],
        customAmount: entryData.customAmount || 0,
        balanceAfter: newBalance, // Storing the state at this point in time
        description: entryData.description || '',
        date: Timestamp.fromDate(new Date(entryData.date)),
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      };

      transaction.set(entryDocRef, newEntry);

      // 4. Update System Stats
      const statsRef = doc(db, 'system', 'stats');
      const statsField = `total${partner.type.charAt(0).toUpperCase() + partner.type.slice(1)}Entries`;
      transaction.set(statsRef, { [statsField]: increment(1) }, { merge: true });

      return entryDocRef.id;
    });

    return NextResponse.json({ success: true, id: entryId });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
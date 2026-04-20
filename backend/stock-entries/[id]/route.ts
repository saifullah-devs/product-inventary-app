// src/app/api/stock-entries/[id]/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { doc, getDoc, updateDoc, serverTimestamp, runTransaction, Timestamp, increment } from 'firebase/firestore';

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const entryData = await request.json();

    const entryRef = doc(db, 'stockEntries', id);
    const entrySnap = await getDoc(entryRef);

    if (!entrySnap.exists()) return NextResponse.json({ error: 'Stock entry not found' }, { status: 404 });
    const entry = entrySnap.data();

    if (entryData.quantity !== undefined && entryData.quantity !== entry.quantity) {
      return NextResponse.json({ error: 'Cannot update quantity of existing stock entry. Create a new entry instead.' }, { status: 400 });
    }
    if (entryData.type !== undefined && entryData.type !== entry.type) {
      return NextResponse.json({ error: 'Cannot change entry type. Create a new entry instead.' }, { status: 400 });
    }
    if (entryData.productId !== undefined && entryData.productId !== entry.productId) {
      return NextResponse.json({ error: 'Cannot change product. Create a new entry instead.' }, { status: 400 });
    }

    const updatePayload: any = {
      ...entryData,
      updatedAt: serverTimestamp()
    };

    if (entryData.date) {
      updatePayload.date = Timestamp.fromDate(new Date(entryData.date));
    }
    if (entryData.productName) {
      updatePayload.productNameLower = entryData.productName.toLowerCase();
    }

    await updateDoc(entryRef, updatePayload);

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;

    await runTransaction(db, async (transaction) => {
      // ==========================================
      // PHASE 1: ALL READS
      // ==========================================
      const entryRef = doc(db, 'stockEntries', id);
      const entryDoc = await transaction.get(entryRef);

      if (!entryDoc.exists()) throw new Error('Stock entry not found');
      const entry = entryDoc.data();

      const productRef = doc(db, 'products', entry.productId);
      const productDoc = await transaction.get(productRef);

      if (!productDoc.exists()) throw new Error('Product not found');

      // Robust check for optional customer
      const hasCustomer = entry.customerId && String(entry.customerId).trim() !== '';
      let partnerDoc = null;
      let partnerRef: any = null;

      if (hasCustomer) {
        partnerRef = doc(db, 'partners', entry.customerId);
        partnerDoc = await transaction.get(partnerRef);

        // Graceful fallback: If the partner was deleted previously, don't crash the deletion of this entry
        if (!partnerDoc.exists()) {
          partnerDoc = null;
          partnerRef = null;
        }
      }

      // ==========================================
      // PHASE 2: CALCULATIONS
      // ==========================================

      // 1. Product Math
      const product = productDoc.data();
      const currentStock = product.stock || 0;
      const lowStockLimit = product.lowStockLimit || 10;

      let newStock;
      if (entry.type === 'in') {
        newStock = currentStock - entry.quantity;
        if (newStock < 0) throw new Error('Cannot delete entry: Would result in negative stock');
      } else if (entry.type === 'out') {
        newStock = currentStock + entry.quantity;
      }
      const isLowStock = newStock <= lowStockLimit;

      // 2. Partner Math (Reverse the Outbound Sale, if a partner still exists)
      let partnerUpdate = null;
      if (partnerDoc && entry.type === 'out') {
        const partner = partnerDoc.data() as any;
        let newBalance = partner.netBalance || 0;
        let newSales = partner.totalSales || 0;

        const entryAmount = Number(entry.totalPrice || entry.amount || (entry.price ? entry.price * entry.quantity : 0)) || 0;

        // Undo the Outbound Sale
        newBalance -= entryAmount;
        newSales = Math.max(0, newSales - entryAmount);

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

      // Update Partner (If applicable)
      if (partnerRef && partnerUpdate) {
        transaction.update(partnerRef, partnerUpdate);
      }

      // Delete Entry & Stats
      transaction.delete(entryRef);

      const statsRef = doc(db, 'system', 'stats');
      transaction.set(statsRef, { totalStockEntries: increment(-1) }, { merge: true });
    });

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
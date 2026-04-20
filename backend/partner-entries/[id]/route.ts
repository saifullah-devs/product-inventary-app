// src/app/api/partner-entries/[id]/route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { doc, getDoc, serverTimestamp, runTransaction, increment } from 'firebase/firestore';

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;

    await runTransaction(db, async (transaction) => {
      // ==========================================
      // PHASE 1: ALL READS
      // ==========================================
      const entryRef = doc(db, 'partnerEntries', id);
      const entryDoc = await transaction.get(entryRef);

      if (!entryDoc.exists()) throw new Error('Entry not found');
      const entry = entryDoc.data();

      const partnerRef = doc(db, 'partners', entry.partnerId);
      const partnerDoc = await transaction.get(partnerRef);

      if (!partnerDoc.exists()) throw new Error('Partner not found');

      // Read all products involved in this entry to reverse their stock
      const productDocsMap = new Map();
      if (entry.entryMethod === 'bill' && entry.items && entry.items.length > 0) {
        for (const item of entry.items) {
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

      // Reverse the financial logic unconditionally
      if (entry.type === 'in') {
        newBalance += entry.amount; // Undo 'in' by adding it back
        newPurchases = Math.max(0, newPurchases - entry.amount); // Deduct from total purchases (minimum 0)
      } else if (entry.type === 'out') {
        newBalance -= entry.amount; // Undo 'out' by subtracting it back
        newSales = Math.max(0, newSales - entry.amount); // Deduct from total sales (minimum 0)
      }

      // Reverse the stock logic if it was a bill
      const productUpdates = [];
      if (entry.entryMethod === 'bill' && entry.items && entry.items.length > 0) {
        for (const item of entry.items) {
          const { ref, data: productData } = productDocsMap.get(item.productId);
          const currentStock = productData.stock || 0;
          const lowStockLimit = productData.lowStockLimit || 10; // Extract limit
          let newStock = currentStock;

          if (entry.type === 'out') {
            // Reversing an 'out' sale -> stock goes UP
            newStock = currentStock + item.quantity;
          } else if (entry.type === 'in') {
            // Reversing an 'in' purchase -> stock goes DOWN
            if (currentStock < item.quantity) {
              throw new Error(`Cannot void: Insufficient stock to reverse purchase of ${item.name}. Available: ${currentStock}, To Reverse: ${item.quantity}`);
            }
            newStock = currentStock - item.quantity;
          }

          // Calculate new boolean based on limit
          const isLowStock = newStock <= lowStockLimit;

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
          isLowStock: update.isLowStock, // FIX: Inject the boolean when reversing
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

      // 3. Delete Ledger Entry
      transaction.delete(entryRef);

      // 4. Update System Stats
      const statsRef = doc(db, 'system', 'stats');
      const statsField = `total${entry.partnerType.charAt(0).toUpperCase() + entry.partnerType.slice(1)}Entries`;
      transaction.set(statsRef, { [statsField]: increment(-1) }, { merge: true });
    });

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
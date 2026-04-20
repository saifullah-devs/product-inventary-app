// src\app\api\stats\route.ts
import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { doc, getDoc } from 'firebase/firestore';

export async function GET() {
  try {
    const statsDoc = await getDoc(doc(db, 'system', 'stats'));
    
    // If the document doesn't exist yet, return all zeros
    if (!statsDoc.exists()) {
      return NextResponse.json({
        totalBuyerEntries: 0,
        totalBuyers: 0,
        totalCategories: 0,
        totalCustomerEntries: 0,
        totalCustomers: 0,
        totalProducts: 0,
        totalStockEntries: 0,
        totalSupplierEntries: 0,
        totalSuppliers: 0,
        totalUnits: 0,
      });
    }

    const data = statsDoc.data();

    // Map the database names to the exact keys your DashboardStats component expects
    const stats = {
      totalBuyerEntries: data.totalBuyerEntries || 0,
      totalBuyers: data.totalBuyers || 0,
      totalCategories: data.totalCategories || 0,
      totalCustomerEntries: data.totalCustomerEntries || 0,
      totalCustomers: data.totalCustomers || 0,
      totalProducts: data.totalProducts || 0,
      totalStockEntries: data.totalStockEntries || 0,
      totalSupplierEntries: data.totalSupplierEntries || 0,
      totalSuppliers: data.totalSuppliers || 0,
      totalUnits: data.totalUnits || 0,
    };

    return NextResponse.json(stats);
  } catch (error: any) {
    console.error('Error fetching stats:', error);
    return NextResponse.json({ error: 'Failed to fetch stats', details: error.message }, { status: 500 });
  }
}
import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can add new location",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('trip_guide', 'add-location', [
        types.ascii("Kid's Play Park"),
        types.int(40750000),
        types.int(-73980000),
        types.ascii("playground"),
        types.ascii("Family-friendly park with modern playground equipment")
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
    let getLocation = chain.callReadOnlyFn(
      'trip_guide',
      'get-location',
      [types.uint(1)],
      deployer.address
    );
    
    let location = getLocation.result.expectSome().expectTuple();
    assertEquals(location['name'], "Kid's Play Park");
    assertEquals(location['verified'], false);
  }
});

Clarinet.test({
  name: "Can create new guide",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // First add some locations
    chain.mineBlock([
      Tx.contractCall('trip_guide', 'add-location', [
        types.ascii("Stop 1"),
        types.int(40750000),
        types.int(-73980000),
        types.ascii("restaurant"),
        types.ascii("Family restaurant")
      ], deployer.address),
      Tx.contractCall('trip_guide', 'add-location', [
        types.ascii("Stop 2"),
        types.int(40760000),
        types.int(-73990000),
        types.ascii("park"),
        types.ascii("Park description")
      ], deployer.address)
    ]);
    
    let block = chain.mineBlock([
      Tx.contractCall('trip_guide', 'create-guide', [
        types.ascii("Family Fun Day"),
        types.list([types.uint(1), types.uint(2)])
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
    let getGuide = chain.callReadOnlyFn(
      'trip_guide',
      'get-guide',
      [types.uint(1)],
      deployer.address
    );
    
    let guide = getGuide.result.expectSome().expectTuple();
    assertEquals(guide['title'], "Family Fun Day");
  }
});

Clarinet.test({
  name: "Only owner can verify locations",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Add location
    chain.mineBlock([
      Tx.contractCall('trip_guide', 'add-location', [
        types.ascii("Test Location"),
        types.int(40750000),
        types.int(-73980000),
        types.ascii("test"),
        types.ascii("Test description")
      ], deployer.address)
    ]);
    
    // Try to verify with non-owner
    let block1 = chain.mineBlock([
      Tx.contractCall('trip_guide', 'verify-location', [
        types.uint(1)
      ], wallet1.address)
    ]);
    
    block1.receipts[0].result.expectErr().expectUint(100);
    
    // Verify with owner
    let block2 = chain.mineBlock([
      Tx.contractCall('trip_guide', 'verify-location', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    block2.receipts[0].result.expectOk().expectBool(true);
  }
});
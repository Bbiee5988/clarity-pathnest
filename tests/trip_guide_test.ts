import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can add new location with photos",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('trip_guide', 'add-location', [
        types.ascii("Kid's Play Park"),
        types.int(40750000),
        types.int(-73980000),
        types.ascii("playground"),
        types.ascii("Family-friendly park with modern playground equipment"),
        types.list([types.ascii("photo1.jpg"), types.ascii("photo2.jpg")])
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
  name: "Can add review to location",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // First add location
    chain.mineBlock([
      Tx.contractCall('trip_guide', 'add-location', [
        types.ascii("Test Location"),
        types.int(40750000),
        types.int(-73980000),
        types.ascii("test"),
        types.ascii("Test description"),
        types.list([])
      ], deployer.address)
    ]);
    
    // Add review
    let block = chain.mineBlock([
      Tx.contractCall('trip_guide', 'add-location-review', [
        types.uint(1),
        types.ascii("Great place for kids!")
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    let getLocation = chain.callReadOnlyFn(
      'trip_guide',
      'get-location',
      [types.uint(1)],
      deployer.address
    );
    
    let location = getLocation.result.expectSome().expectTuple();
    let reviews: any = location['reviews'];
    assertEquals(reviews.length, 1);
  }
});

Clarinet.test({
  name: "Can follow curator",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // First create a guide to establish curator
    chain.mineBlock([
      Tx.contractCall('trip_guide', 'create-guide', [
        types.ascii("Test Guide"),
        types.list([])
      ], deployer.address)
    ]);
    
    // Follow curator
    let block = chain.mineBlock([
      Tx.contractCall('trip_guide', 'follow-curator', [
        types.principal(deployer.address)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    let getCurator = chain.callReadOnlyFn(
      'trip_guide',
      'get-curator-info',
      [types.principal(deployer.address)],
      deployer.address
    );
    
    let curator = getCurator.result.expectSome().expectTuple();
    let followers: any = curator['followers'];
    assertEquals(followers.length, 1);
  }
});

Clarinet.test({
  name: "Can favorite and comment on guide",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create guide
    chain.mineBlock([
      Tx.contractCall('trip_guide', 'create-guide', [
        types.ascii("Test Guide"),
        types.list([])
      ], deployer.address)
    ]);
    
    // Favorite guide
    let block1 = chain.mineBlock([
      Tx.contractCall('trip_guide', 'favorite-guide', [
        types.uint(1)
      ], wallet1.address)
    ]);
    
    block1.receipts[0].result.expectOk().expectBool(true);
    
    // Comment on guide
    let block2 = chain.mineBlock([
      Tx.contractCall('trip_guide', 'comment-on-guide', [
        types.uint(1),
        types.ascii("Great guide!")
      ], wallet1.address)
    ]);
    
    block2.receipts[0].result.expectOk().expectBool(true);
    
    let getGuide = chain.callReadOnlyFn(
      'trip_guide',
      'get-guide',
      [types.uint(1)],
      deployer.address
    );
    
    let guide = getGuide.result.expectSome().expectTuple();
    let favorites: any = guide['favorited-by'];
    let comments: any = guide['comments'];
    assertEquals(favorites.length, 1);
    assertEquals(comments.length, 1);
  }
});

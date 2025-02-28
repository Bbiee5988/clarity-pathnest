[Previous test content remains unchanged...]

Clarinet.test({
  name: "Cannot rate location with invalid rating",
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
    
    // Try to rate with invalid rating
    let block = chain.mineBlock([
      Tx.contractCall('trip_guide', 'rate-location', [
        types.uint(1),
        types.uint(6)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectErr().expectUint(104);
  }
});

Clarinet.test({
  name: "Can unfollow curator",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // First follow curator
    chain.mineBlock([
      Tx.contractCall('trip_guide', 'follow-curator', [
        types.principal(deployer.address)
      ], wallet1.address)
    ]);
    
    // Then unfollow
    let block = chain.mineBlock([
      Tx.contractCall('trip_guide', 'unfollow-curator', [
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
    assertEquals(followers.length, 0);
  }
});

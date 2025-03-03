Clarinet.test({
  name: "Validates coordinate ranges correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Test invalid latitude
    let block = chain.mineBlock([
      Tx.contractCall('trip_guide', 'add-location', [
        types.ascii("Test Location"),
        types.int(95),  // Invalid latitude
        types.int(-73980000),
        types.ascii("test"),
        types.ascii("Test description"),
        types.list([])
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectErr().expectUint(107);
    
    // Test valid coordinates
    block = chain.mineBlock([
      Tx.contractCall('trip_guide', 'add-location', [
        types.ascii("Test Location"),
        types.int(40750000),
        types.int(-73980000),
        types.ascii("test"),
        types.ascii("Test description"),
        types.list([types.ascii("http://example.com/photo.jpg")])
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
  }
});

[Previous tests remain unchanged...]

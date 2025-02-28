[Previous test content remains, adding new tests...]

Clarinet.test({
  name: "Can transfer collection ownership",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create collection
    let block = chain.mineBlock([
      Tx.contractCall('frame-nest', 'create-collection', [
        types.ascii("Transfer Test"),
        types.ascii("Test Description")
      ], deployer.address)
    ]);
    
    // Transfer ownership
    let transferBlock = chain.mineBlock([
      Tx.contractCall('frame-nest', 'transfer-collection', [
        types.uint(1),
        types.principal(wallet1.address)
      ], deployer.address)
    ]);
    
    transferBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Verify new owner
    let getCollection = chain.mineBlock([
      Tx.contractCall('frame-nest', 'get-collection', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    const collection = getCollection.receipts[0].result.expectOk().expectSome();
    assertEquals(collection['owner'], wallet1.address);
  },
});

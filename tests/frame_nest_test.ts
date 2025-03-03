Clarinet.test({
  name: "Can retrieve photos in batches",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Create collection and add photos
    let block = chain.mineBlock([
      Tx.contractCall('frame-nest', 'create-collection', [
        types.ascii("Batch Test"),
        types.ascii("Test Description")
      ], deployer.address)
    ]);
    
    // Add multiple photos
    let photoBlocks = chain.mineBlock([
      Tx.contractCall('frame-nest', 'add-photo', [
        types.uint(1),
        types.utf8("https://test1.com"),
        types.utf8("{}")
      ], deployer.address),
      Tx.contractCall('frame-nest', 'add-photo', [
        types.uint(1),
        types.utf8("https://test2.com"),
        types.utf8("{}")
      ], deployer.address)
    ]);
    
    // Retrieve photos in batch
    let getPhotos = chain.mineBlock([
      Tx.contractCall('frame-nest', 'get-collection-photos', [
        types.uint(1),
        types.uint(1),
        types.uint(2)
      ], deployer.address)
    ]);
    
    getPhotos.receipts[0].result.expectOk();
  },
});

[Previous tests remain unchanged...]

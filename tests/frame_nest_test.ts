import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create a new collection",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('frame-nest', 'create-collection', [
        types.ascii("Vacation 2023"),
        types.ascii("My summer vacation photos")
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
    let getCollection = chain.mineBlock([
      Tx.contractCall('frame-nest', 'get-collection', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    const collection = getCollection.receipts[0].result.expectOk().expectSome();
    assertEquals(collection['name'], "Vacation 2023");
  },
});

Clarinet.test({
  name: "Can add photo to collection and set permissions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create collection
    let block = chain.mineBlock([
      Tx.contractCall('frame-nest', 'create-collection', [
        types.ascii("Test Collection"),
        types.ascii("Test Description")
      ], deployer.address)
    ]);
    
    // Add photo
    let photoBlock = chain.mineBlock([
      Tx.contractCall('frame-nest', 'add-photo', [
        types.uint(1),
        types.utf8("https://example.com/photo1.jpg"),
        types.utf8("{\"title\":\"Beach Day\"}")
      ], deployer.address)
    ]);
    
    photoBlock.receipts[0].result.expectOk().expectUint(1);
    
    // Set permissions for wallet1
    let permissionBlock = chain.mineBlock([
      Tx.contractCall('frame-nest', 'set-permissions', [
        types.uint(1),
        types.principal(wallet1.address),
        types.bool(true),
        types.bool(false)
      ], deployer.address)
    ]);
    
    permissionBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Verify permissions
    let getPermissions = chain.mineBlock([
      Tx.contractCall('frame-nest', 'get-permissions', [
        types.uint(1),
        types.principal(wallet1.address)
      ], deployer.address)
    ]);
    
    const permissions = getPermissions.receipts[0].result.expectOk().expectSome();
    assertEquals(permissions['can-view'], true);
    assertEquals(permissions['can-edit'], false);
  },
});
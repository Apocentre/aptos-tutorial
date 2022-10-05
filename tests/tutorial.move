#[test_only]
module tutorial::ticket_test {
  use std::signer;
  use std::vector;
  use std::math64;
  use aptos_framework::account;
  use aptos_framework::managed_coin;
  use aptos_framework::coin;
  use std::type_info::{
    TypeInfo,
    type_of,
  };
  use tutorial::ticket::{
    initialize,
    create_ticket,
    create_venue,
    available_tickets,
    venue_exists,
    get_ticket_info,
    purchase_ticket,
    get_user_ticket,
  };

  struct USDC {}
  struct USDT {}
  struct NOT_SUPPORTED {}

  const DECIMALS: u8 = 6;

  fun to_base(val: u64): u64 {
    val * math64::pow(10, 6)
  }

  // create coin types that will be used in our tests. These are all the coins the one can use
  // to purchase a ticket
  fun create_test_coins(owner: &signer, venue_owner: &signer, buyers: &vector<signer>): vector<TypeInfo>{
    managed_coin::initialize<USDC>(
      owner,
      b"USDC",
      b"USDC",
      DECIMALS,
      false,
    );
    managed_coin::initialize<USDT>(
      owner,
      b"USDT",
      b"USDT",
      DECIMALS,
      false,
    );
    managed_coin::initialize<NOT_SUPPORTED>(
      owner,
      b"NOT_SUPPORTED",
      b"BTC",
      DECIMALS,
      false,
    );

    // fund the buyers' accounts
    let count = vector::length<signer>(buyers);
    let i = 0;

    while (i < count) {
      let buyer = vector::borrow<signer>(buyers, i);
      let buyer_address = signer::address_of(buyer);
      account::create_account_for_test(buyer_address);
      
      coin::register<USDC>(buyer);
      managed_coin::mint<USDC>(owner, buyer_address, to_base(100));
      coin::register<USDT>(buyer);
      managed_coin::mint<USDT>(owner, buyer_address, to_base(100));
      coin::register<NOT_SUPPORTED>(buyer);
      managed_coin::mint<NOT_SUPPORTED>(owner, buyer_address, to_base(100));

      i = i + 1;
    };
    
    // register the venue owner as well as it will be receiving the funds from the purchase
    account::create_account_for_test(signer::address_of(venue_owner));
    coin::register<USDT>(venue_owner);
    coin::register<USDC>(venue_owner);
    coin::register<NOT_SUPPORTED>(venue_owner);

    let supported_coins = vector[type_of<USDC>(), type_of<USDT>()];

    supported_coins
  }

  fun test_initialize(owner: &signer, venue_owner: &signer, buyers: &vector<signer>) {
    let supported_coins = create_test_coins(owner, venue_owner, buyers);
    initialize(owner, supported_coins);
  }
  
  #[test(venue_owner = @0x0123)]
  #[expected_failure(abort_code = 0)]
  fun should_fail_if_venue_is_not_created_yet(venue_owner: signer) {
    create_ticket(&venue_owner, b"seat_1", b"ticket_code_1", 100);
  }

  #[test(venue_owner = @0x0123)]
  fun should_create_ticket(venue_owner: signer) {
    create_venue(&venue_owner, 100000);
    create_ticket(&venue_owner, b"seat_1", b"ticket_code_1", 100);
    create_ticket(&venue_owner, b"seat_2", b"ticket_code_2", 200);
    create_ticket(&venue_owner, b"seat_3", b"ticket_code_3", 300);

    let venue_owner_addr = signer::address_of(&venue_owner);
    account::create_account_for_test(venue_owner_addr);
    assert!(available_tickets(venue_owner_addr) == 3, 1);

    // test ticket values
    let (_, ticket_code, price) = get_ticket_info(venue_owner_addr, b"seat_1");
    assert!(ticket_code == b"ticket_code_1", 5);
    assert!(price == 100, 0);

    let (_, ticket_code, price) = get_ticket_info(venue_owner_addr, b"seat_2");
    assert!(ticket_code == b"ticket_code_2", 5);
    assert!(price == 200, 0);

    let (_, ticket_code, price) = get_ticket_info(venue_owner_addr, b"seat_3");
    assert!(ticket_code == b"ticket_code_3", 5);
    assert!(price == 300, 0);
  }
  
  #[test(venue_owner = @0x0123)]
  fun should_create_venue(venue_owner: signer) {
    create_venue(&venue_owner, 100000);
    let venue_owner_addr = signer::address_of(&venue_owner);
    account::create_account_for_test(venue_owner_addr);
    assert!(venue_exists(venue_owner_addr), 1);
  }

  #[test(owner = @tutorial, venue_owner = @0xb, buyer1 = @0xc, buyer2 = @0xd)]
  fun should_allow_purchase(owner: signer, venue_owner: signer, buyer1: signer, buyer2: signer) {
    create_venue(&venue_owner, 100000);
    create_ticket(&venue_owner, b"seat_1", b"ticket_code_1", to_base(10));
    create_ticket(&venue_owner, b"seat_2", b"ticket_code_2", to_base(20));
    
    let buyers = vector [buyer1, buyer2];
    test_initialize(&owner, &venue_owner, &buyers);
    
    purchase_ticket<USDC>(
      vector::borrow(&buyers, 0),
      signer::address_of(&owner),
      signer::address_of(&venue_owner),
      b"seat_1",
    );

    // check that venue owner received the ticke price
    let balance = coin::balance<USDC>(signer::address_of(&venue_owner));
    assert!(balance == to_base(10), 1);

    // check that ticket resource is owned by the buyer
    let buyer = signer::address_of(vector::borrow(&buyers, 0));
    let (seat, ticket_code, price) = get_user_ticket(buyer, 0);
    assert!(seat == b"seat_1", 1);
    assert!(ticket_code == b"ticket_code_1", 1);
    assert!(price == to_base(10), 1);
  }

  #[test(owner = @tutorial, venue_owner = @0xb, buyer = @0xc)]
  #[expected_failure(abort_code = 8)]
  fun should_fail_if_purchase_with_unsopported_coint(owner: signer, venue_owner: signer, buyer: signer) {
    create_venue(&venue_owner, 100000);
    create_ticket(&venue_owner, b"seat_1", b"ticket_code_1", to_base(10));
    
    let buyers = vector [buyer];
    test_initialize(&owner, &venue_owner, &buyers);
    
    purchase_ticket<NOT_SUPPORTED>(
      vector::borrow(&buyers, 0),
      signer::address_of(&owner),
      signer::address_of(&venue_owner),
      b"seat_1",
    );
  }
}

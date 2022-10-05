#[test_only]
module tutorial::ticket_test {
  use std::signer;
  use std::vector;
  use aptos_framework::managed_coin;
  use aptos_framework::coin;
  use tutorial::ticket::{
    initialize,
    create_ticket,
    create_venue,
    available_tickets,
    venue_exists,
    get_ticket_info,
  };

  struct USDC {}
  struct USDT {}

  const DECIMALS: u8 = 6;
  const UNIT: u64 = 10 ^ 6;

  // create coin types that will be used in our tests. These are all the coins the one can use
  // to purchase a ticket
  fun create_test_coins(owner: &signer, buyers: &vector<signer>): vector<address>{
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

    // fund the buyers' accounts
    let count = vector::length<signer>(buyers);
    let i = 0;

    while (i < count) {
      let buyer = vector::borrow<signer>(buyers, i);
      coin::register<USDC>(buyer);
      managed_coin::mint<USDC>(owner, signer::address_of(buyer), 100 * UNIT);

      coin::register<USDT>(buyer);
      coin::register<USDT>(buyer);
      managed_coin::mint<USDT>(owner, signer::address_of(buyer), 100 * UNIT);
    };

    let supported_coins = vector::empty<address>();
    vector::push_back(&mut supported_coins, @tutorial);
    vector::push_back(&mut supported_coins, @tutorial);

    supported_coins
  }

  fun test_initialize(owner: &signer, buyers: vector<signer>) {
    let supported_coins = create_test_coins(owner, &buyers);
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
    aptos_framework::account::create_account_for_test(venue_owner_addr);
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
    aptos_framework::account::create_account_for_test(venue_owner_addr);
    assert!(venue_exists(venue_owner_addr), 1);
  }
}

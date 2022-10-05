#[test_only]
module tutorial::ticket_test {
  use std::signer;
  use tutorial::ticket::{
    create_ticket,
    create_venue,
    available_tickets,
    venue_exists,
  };
  
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

  }
  
  #[test(venue_owner = @0x0123)]
  fun should_create_venue(venue_owner: signer) {
    create_venue(&venue_owner, 100000);
    let venue_owner_addr = signer::address_of(&venue_owner);
    aptos_framework::account::create_account_for_test(venue_owner_addr);
    assert!(venue_exists(venue_owner_addr), 1);
  }
}

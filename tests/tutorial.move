#[test_only]
module tutorial::ticket_test {
  use std::signer;
  use tutorial::ticket::{
    create_ticket,
    create_venue,
    ticket_exists,
    venue_exists,
  };
  
  #[test(recipient = @0x0123)]
  fun should_create_ticket(recipient: signer) {
    create_ticket(&recipient, b"seat_1", b"ticket_code_0");
    let recipient_addr = signer::address_of(&recipient);
    aptos_framework::account::create_account_for_test(recipient_addr);
    assert!(ticket_exists(recipient_addr), 1);
  }
  
  #[test(venue_owner = @0x0123)]
  fun should_create_venue(venue_owner: signer) {
    create_venue(&venue_owner, 100000);
    let venue_owner_addr = signer::address_of(&venue_owner);
    aptos_framework::account::create_account_for_test(venue_owner_addr);
    assert!(venue_exists(venue_owner_addr), 1);
  }
}

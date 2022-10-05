#[test_only]
module tutorial::ticket_tests {
  use std::signer;
  use tutorial::ticket::{
    create_ticket,
    ticket_exists,
  };
  
  #[test(recipient = @0x0123)]
  fun should_create_ticket(recipient: signer) {
    create_ticket(&recipient, b"seat_1", b"ticket_code_0");
    let recipient_addr = signer::address_of(&recipient);
    aptos_framework::account::create_account_for_test(recipient_addr);
    assert!(ticket_exists(recipient_addr), 1);
  }
}

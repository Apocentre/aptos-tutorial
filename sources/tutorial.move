module tutorial::ticket {
  struct Ticket has key {
    seat: vector<u8>,
    ticket_code: vector<u8>,
  }

  public fun create_ticket(recipient: &signer, seat: vector<u8>, ticket_code: vector<u8>) {
    move_to(recipient, Ticket {seat, ticket_code});
  }

  public fun ticket_exists(addr: address): bool {
    exists<Ticket>(addr)
  }
}

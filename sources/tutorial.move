module tutorial::ticket {
  use std::vector;

  struct Ticket has key, store {
    seat: vector<u8>,
    ticket_code: vector<u8>,
  }

  struct Venue has key {
    available_tickets: vector<Ticket>,
    max_seats: u64,
  }

  public fun create_venue(venue_owner: &signer, max_seats: u64) {
    let available_tickets = vector::empty<Ticket>();
    move_to(venue_owner, Venue {available_tickets, max_seats});
  }

  public fun create_ticket(recipient: &signer, seat: vector<u8>, ticket_code: vector<u8>) {
    move_to(recipient, Ticket {seat, ticket_code});
  }

  public fun ticket_exists(addr: address): bool {
    exists<Ticket>(addr)
  }

  public fun venue_exists(addr: address): bool {
    exists<Venue>(addr)
  }
}

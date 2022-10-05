module tutorial::ticket {
  use std::vector;
  use std::signer;

  const VENUE_DOES_NOT_EXIST: u64 = 0;
  const ENO_TICKETS: u64 = 1;
  const ENO_ENVELOPE: u64 = 2;
  const EINVALID_TICKET_COUNT: u64 = 3;
  const EINVALID_TICKET: u64 = 4;
  const EINVALID_PRICE: u64 = 5;
  const MAX_VENUE_SEATS: u64 = 6;
  const EINVALID_BALANCE: u64 = 7;
  
  struct Ticket has key, store {
    seat: vector<u8>,
    ticket_code: vector<u8>,
    price: u64,
  }

  struct Venue has key {
    available_tickets: vector<Ticket>,
    max_seats: u64,
  }

  public fun create_venue(venue_owner: &signer, max_seats: u64) {
    let available_tickets = vector::empty<Ticket>();
    move_to(venue_owner, Venue {available_tickets, max_seats});
  }

  public fun create_ticket(
    venue_owner: &signer,
    seat: vector<u8>,
    ticket_code: vector<u8>,
    price: u64,
  ) acquires Venue {
    let venue_owner_addr = signer::address_of(venue_owner);
    assert!(exists<Venue>(venue_owner_addr), VENUE_DOES_NOT_EXIST);
    
    let ticket_count = available_tickets(venue_owner_addr);
    let venue = borrow_global_mut<Venue>(venue_owner_addr);
    assert!(ticket_count <= venue.max_seats, MAX_VENUE_SEATS);
    
    vector::push_back(&mut venue.available_tickets, Ticket {seat, ticket_code, price});
    // move_to(recipient, Ticket {seat, ticket_code});
  }

  public fun venue_exists(addr: address): bool {
    exists<Venue>(addr)
  }

  public fun available_tickets(venue_owner: address): u64 acquires Venue {
    let venue = borrow_global<Venue>(venue_owner);
    vector::length(&venue.available_tickets)
  }
}

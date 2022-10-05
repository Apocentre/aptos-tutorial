module tutorial::ticket {
  use std::signer;
  use std::vector;
  use std::table_with_length::{
    Self as table,
    new as NewTable,
    TableWithLength,
  };

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
    tickets: TableWithLength<vector<u8>, Ticket>,
    max_seats: u64,
  }

  // a resource to hold multiple tickets
  struct TicketEnvelope has key {
    tickets: vector<Ticket>,
  }

  public fun create_venue(venue_owner: &signer, max_seats: u64) {
    let tickets = NewTable<vector<u8>, Ticket>();
    move_to(venue_owner, Venue {tickets, max_seats});
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
    
    table::add(&mut venue.tickets, seat, Ticket {seat, ticket_code, price});
  }

  public fun venue_exists(addr: address): bool {
    exists<Venue>(addr)
  }

  public fun available_tickets(venue_owner: address): u64 acquires Venue {
    let venue = borrow_global<Venue>(venue_owner);
    table::length(&venue.tickets)
  }

  public fun get_ticket_info(venue_owner: address, seat: vector<u8>): (bool, vector<u8>, u64) acquires Venue {
    let venue = borrow_global<Venue>(venue_owner);

    if(!table::contains(&venue.tickets, seat)) {
      return (false, b"", 0)
    };

    let Ticket {seat: _, ticket_code, price} = table::borrow(&venue.tickets, seat);
    
    (true, *ticket_code, *price)
  }

  public fun purchase_ticket(buyer: &signer, venue_owner: address, seat: vector<u8>) acquires Venue, TicketEnvelope {
    let buyer_addr = signer::address_of(buyer);
    
    // make sure ticket exists
    let (success, _, _) = get_ticket_info(venue_owner, seat);
    assert!(success, EINVALID_TICKET);

    let venue = borrow_global_mut<Venue>(venue_owner);
    // TODO: how can we choose which Token can be used
    // TestCoin::transfer_internal(buyer, venue_owner_addr, price);

    let ticket = table::remove(&mut venue.tickets, seat);
    if(!exists<TicketEnvelope>(buyer_addr)) {
      move_to(buyer, TicketEnvelope {tickets: vector::empty()});
    };

    let envelope = borrow_global_mut<TicketEnvelope>(buyer_addr);
    vector::push_back(&mut envelope.tickets, ticket);
  }
}

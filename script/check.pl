#!/usr/bin/perl -w

BEGIN {
    package Certwarner::ScriptOptions;
    use Moose;
    our $VSERION = 0.1;
    with 'MooseX::Getopt';
    has 'host' => ( traits => [qw(Getopt)], cmd_aliases => 'h', is => 'rw', isa => 'Str',  required => 1 );
    has 'port' => ( traits => [qw(Getopt)], cmd_aliases => 'p', is => 'rw', isa => 'Num',  default  => 443 );
    1;
}

use FindBin;
use lib qq[$FindBin::Bin/../lib];

my $options = Certwarner::ScriptOptions->new_with_options();

use Net::HTTPS::Certwarner;
use Try::Tiny;
use feature 'say';

my $checker = Net::HTTPS::Certwarner->new(
    host => $options->{host},
    port => $options->{port},
);
my $message = $checker->check;

if ( $message->{is_ok} ) {
    say "certificate is fine today!";
    my $in_a_week = $checker->check( date_within => DateTime->now->add( days => 7 ) );
    say  "...but it needs to be renewed soon!" if not $in_a_week->{is_ok};
}
else {
    say "certificate is out of date! " . $message->{error};
    say "valid from: " . $message->{not_before}->dmy . ' till ' . $message->{not_after}->dmy;

};


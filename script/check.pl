#!/usr/bin/perl -w

BEGIN {
    package Certwarner::ScriptOptions;
    use Moose;
    our $VSERION = 0.1;
    with 'MooseX::Getopt';
    has 'host'  => ( traits => [qw(Getopt)], cmd_aliases => 'h', is => 'rw', isa => 'Str',  required => 1 );
    has 'port'  => ( traits => [qw(Getopt)], cmd_aliases => 'p', is => 'rw', isa => 'Num',  default  => 443 );
    has 'quiet' => ( traits => [qw(Getopt)], cmd_aliases => 'q', is => 'rw', isa => 'Bool', default  => 0 );
    1;
}

use FindBin;
use lib qq[$FindBin::Bin/../lib];

our $options = Certwarner::ScriptOptions->new_with_options();

use Net::HTTPS::Certwarner;
use Try::Tiny;
use feature 'say';

sub ssay {
    say shift if not $options->{quiet};
}

my $checker = Net::HTTPS::Certwarner->new(
    host => $options->{host},
    port => $options->{port},
);
my $message = $checker->check;

if ( $message->{is_ok} ) {
    ssay "certificate is fine today!";
    my $in_a_week = $checker->check( date_within => DateTime->now->add( days => 7 ) );
    ssay  "...but it needs to be renewed soon!" if not $in_a_week->{is_ok};
    exit 0 if $in_a_week->{is_ok};
}
else {
    ssay "certificate is out of date! " . $message->{error};
    ssay "valid from: " . $message->{not_before}->dmy . ' till ' . $message->{not_after}->dmy;
};

exit 1;

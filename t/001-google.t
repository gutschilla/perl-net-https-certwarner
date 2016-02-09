#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dump 'dump';
use Try::Tiny;

require_ok('Net::HTTPS::Certwarner');

my $warner = Net::HTTPS::Certwarner->new( host => 'google.com' );
my $result = $warner->check();

ok( $result->{is_ok}, 'google.com should come with a proper TLS certificate' );

my $result2 = $warner->check( date_within => DateTime->now->add( years => 15 ) );

ok( not( $result2->{is_ok} ), 'google.com\'s certificate should not be valid 15 years from now' );

try {
    my $result3 = $warner->check( die_on_error => 1, date_within => DateTime->new( year => 1990, month => 1, day => 1 ) );
    fail('invalid certs should fail when die_on_error is set');
}
catch {
    ok('invalid certs should fail when die_on_error is set');
};

done_testing();


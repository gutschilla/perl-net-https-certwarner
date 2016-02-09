package Net::HTTPS::Certwarner;

our $VERSION = 0.02;

=head1 NAME 

Net::HTTPS::Certwarner - checks for TLS certificate date validity

=head1 SYNOPSIS
    
    use Net::HTTPS::Certwarner;
    use Try::Tiny;
    use feature 'say';

    my $checker = Net::HTTPS::Certwarner->new(
        host => 'google.com' # checks https://google.com
    );
    my $message = $checker->check;

    if ( $message->{is_ok} ) {
        say "certificate is fine today!";
        my $in_a_week = $checker->check( DateTime->now->add( days => 7 ) );
        say  "...but it needs to be renewed soon!" if not $in_a_week->{is_ok};
    }
    else {
        say "certificate is out of date! " . $_->{error};
        say "valid from: " . $message->{not_before}->dmy . ' till ' . $message->{not_after}->dmy;

    };

=head1 CLI usage

    perl script/check.pl --host google.com

=head1 DESCRIPTION

Certwarner will connect to a HTTPS service (requesting "/" ) and inspect the
server's certificate to be valid on a certain date.

This is mainly used to do automated tests that warn if a certficiate is about to
expire soon.

=over

=item $checker = Net::HTTPS::Certwarner->new( %options )

The constructor takes two options
    
    host:   FQDN string of service to check (mandatory)
    port:   optional port (443 is default)

=item $checker->checkk( %options )

Performs the actual check by sending a GET requests over TLS to "/". This will
also ensure that the service is respoinding to HTTP requests.

Takes options:
    
    die_on_error:   boolean. Die if cert check fails (default false)
    date_within:    DateTime instance to check for (defaults to now)

Will return a hashref containing these keys

    is_ok:          boolean, true if certificate is valid
    not_after:      DateTime instance. Until when the cert is valid
    not_before:     DateTime instance. Since when the cert is vaild
    error:          Striug. Only set up on error. Contains error message.

=back

=head1 LICENSE

This is free software licensde under the MIT licence. See LICENSE file of this
package for details.

=head1 CHANGES

=over

=item 0.02

first working release

=back

=cut

use Moose;
use Net::HTTPS;
use Data::Dump;
use IO::Socket::SSL::Utils;
use DateTime;

has 'host' => ( is => 'ro', isa => 'Str', required => 1 );
has 'port' => ( is => 'ro', isa => 'Int', default => 443 );

sub check {
    my ( $self, %options ) = @_;

    my $s = Net::HTTPS->new( Host => $self->host, Port => $self->port ) || die $@;
    $s->write_request( GET => "/", 'User-Agent' => "Mozilla/5.0");

    my $cert = CERT_asHash( $s->peer_certificate );
    my $not_before_epoch = $cert->{not_before};
    my $not_after_epoch  = $cert->{not_after};

    my $not_before  = DateTime->from_epoch( epoch => $not_before_epoch );
    my $not_after   = DateTime->from_epoch( epoch => $not_after_epoch );
    my $date_within = $options{ date_within } || DateTime->now;

    my $has_expired  = $date_within > $not_after;
    my $is_in_future = $date_within < $not_before;

    my $is_ok = not ( $has_expired || $is_in_future );
    
    my $message = {
        is_ok      => $is_ok,
        not_before => $not_before,
        not_after  => $not_after,
        cert       => $cert,
    };
    
    $message->{error} 
        = $is_in_future ? 'validity is in future'
        : $has_expired  ? 'cert has expired'
        : 'unknown error'
    if not $is_ok;

    return $message if $is_ok;
    die $message if $options{ die_on_error };
    return $message;
}

1;

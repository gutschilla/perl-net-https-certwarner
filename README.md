# NAME 

Net::HTTPS::Certwarner - checks for TLS certificate date validity

# SYNOPSIS
```perl
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
```
# CLI usage
```
    perl script/check.pl --host google.com
```
# DESCRIPTION

Certwarner will connect to a HTTPS service (requesting "/" ) and inspect the
server's certificate to be valid on a certain date.

This is mainly used to do automated tests that warn if a certficiate is about to
expire soon.

- $checker = Net::HTTPS::Certwarner->new( %options )

    The constructor takes two options

        host:   FQDN string of service to check (mandatory)
        port:   optional port (443 is default)

- $checker->checkk( %options )

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

# LICENSE

This is free software licensde under the MIT licence. See LICENSE file of this
package for details.

# CHANGES

- 0.02

    first working release

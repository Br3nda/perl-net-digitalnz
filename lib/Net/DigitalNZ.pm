package Net::DigitalNZ;
#Based heavily on Net::Twitter


$VERSION = "0.04";
use 5.005;
use strict;

use URI::Escape;
use JSON::Any 1.19;
use LWP::UserAgent 2.032;
use Carp;

sub new {
my $class = shift;

my %conf;

if ( scalar @_ == 1 ) {
  if ( ref $_[0] ) {
    %conf = %{ $_[0] };
    } else {
      croak "Bad argument \"" . $_[0] . "\" passed, please pass a hashref containing config values.";
    }
  }
  else {
    %conf = @_;
  }
  $conf{apiurl}   = 'http://api.digitalnz.org/' unless defined $conf{apiurl};

  ### Set useragents, HTTP Headers, source codes.
  $conf{useragent} = "Net::DigitalNZ/$Net::DigitalNZ::VERSION (PERL)"
  unless defined $conf{useragent};
  ### Allow specifying a class other than LWP::UA

  $conf{no_fallback} = 0 unless defined $conf{no_fallback};
  $conf{useragent_class} ||= '';

  ### Create an LWP Object to work with
  $conf{ua} = LWP::UserAgent->new();


  $conf{ua}->env_proxy();

  $conf{response_error}  = undef;
  $conf{response_code}   = undef;
  $conf{response_method} = undef;

  return bless {%conf}, $class;
}
                        
### Return a shallow copy of the object to allow error handling when used in
### Parallel/Async setups like POE. Set response_error to undef to prevent
### spillover, just in case.

sub clone {
  my $self = shift;
  bless { %{$self}, response_error => $self->{error_return_val} };
}
                        

                        
sub get_error {
  my $self = shift;
  my $response = eval { JSON::Any->jsonToObj( $self->{response_error} ) };

  if ( !defined $response ) {
    $response = {
    request => undef,
    error   => "DIGITAL NZ RETURNED ERROR MESSAGE BUT PARSING OF THE JSON RESPONSE FAILED - "
    . $self->{response_error}
    };
  }

  return $response;

}
                          
sub http_code {
  my $self = shift;
  return $self->{response_code};
}

sub http_message {
  my $self = shift;
  return $self->{response_message};
}

sub search {
    my $self = shift;
    my $query = shift;
    my $params = shift;
    
    my $url  = $self->{apiurl} . "records/v1.json/?";
    $url .= 'api_key='. $self->{api_key};
    $url .= '&search_text='. $query;
    my $retval;
    ### Make the request, store the results.
    my $req = $self->{ua}->get($url);

    $self->{response_code}    = $req->code;
    $self->{response_message} = $req->message;
    $self->{response_error}   = $req->content;

    undef $retval;
                                                
    ### Trap a case where digitalnz could return a 200 success but give up badly formed JSON
    ### which would cause it to die. This way it simply assigns undef to $retval
    ### If this happens, response_code, response_message and response_error aren't going to
    ### have any indication what's wrong, so we prepend a statement to request_error.
                                                
  if ( $req->is_success ) {
    $retval = eval { JSON::Any->jsonToObj( $req->content ) };

    if ( !defined $retval ) {
      $self->{response_error} =
      "DIGITALNZ RETURNED SUCCESS BUT PARSING OF THE RESPONSE FAILED - " . $req->content;
      return $self->{error_return_val};
      }
  }
  return $retval;
} 

1;
__END__
                                                                                                                    
=head1 NAME

Net::DigitalNZ - Perl interface to digitalnz.org.nz 's open data api.

=head1 SYNOPSIS
      
use Net::DigitalNZ;

my $query = 'Waitangi';
      
my $api_key = 'get your own api key from http://digitalnz.org.nz';

my $searcher = Net::DigitalNZ->new(api_key => $api_key);


my $results = $searcher->search($query);

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 VERSION CONTROL

http://github.com/Br3nda/perl-net-digitalnz/tree/master
      
=head1 AUTHOR

Brenda Wallace <brenda@wallace.net.nz> http://br3nda.com
      
Based heavily on Net::Twitter by Chris Thompson

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
                                                                                                                    
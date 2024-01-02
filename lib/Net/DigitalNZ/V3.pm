package Net::DigitalNZ::V3;

use 5.32.0;

our $VERSION = "1.0";
use Moo;
use strictures 2;

use Carp;
use JSON::MaybeXS;
use List::Util qw( pairs );
use LWP::UserAgent;
use URI;
use URI::Escape;

use namespace::clean;

=head1 NAME

Net::DigitalNZ::V3 - an interface to the DigitalNZ version 3 open data API

=head1 DESCRIPTION

This provides access to the DigitalNZ content API. DigitalNZ aggregates data
across museums, libraries, universities, and other cultural sources, providing
a common API to these collections.

A more comprehensive explanation of DigitalNZ can be found on their
L<about page|https://digitalnz.org/about>. This module is based on their
L<developer documentation|https://digitalnz.org/developers/api-docs-v3> and their
L<swagger documentation|https://app.swaggerhub.com/apis-docs/DigitalNZ/Records/3>.

=head1 SYNOPSIS

    use Net::DigitalNZ::V3;
    my $dnz = Net::DigitalNZ->new({
        version => 3,
        api_key => 'your key', # optional
    });
    # or
    my $dnz = Net::DigitalNZ::V3->new(
        api_key => 'your key', # still optional
    );

    # Search for something
    my $results = $dnz->search(
        text => 'Pōneke',
        filters => {
            ...
        },
        page => 13,
        per_page => 20,
        # refer to the API documentation for all possible fields
    );

    # Get more details on something
    my $record = $dnz->metadata(
        record_id => 22734807,
        fields    => 'verbose',
    );

=head1 METHODS

=head2 new

    my $dnz = Net::DigitalNZ::V3->new(
        api_key => 'your key',
    );
    
                
Create a new instance of the DigitalNZ v3 API client.

=head3 Parameters:

=over 4

=item C<api_key>

If provided, the C<api_key> argument will be use to authenticate with the API.

=item C<base_url>

The base URL to access DigitalNZ with, the default is C<https://api.digitalnz.org/v3/>.

=item C<useragent>

What the user agent sent to DigitalNZ is set to. It's recommended to override
this with something that is connected to your application.

=back

=head2 search

    my $results = $dnz->search(
        text => 'Pōneke',
    );

Performs a search on the DigitalNZ API. All parameters are optional. The
parameters are defined in the DigitalNZ docs, in particular the swagger
definition. Where they differ, the swagger will generally be followed.

C<filters> are a simplified and hopefully more convenient version of how the API
does filtering, with the caveat that it doesn't support nesting. 

    filters => {
        -and => [
            content_partner => 'Ministry for Culture and Heritage', # can be repeated
            collection => 'Mollusks',
        ],
        -or => [
            category => 'Images',
            subject => 'cats',
            subject => 'dogs',
        ],
        -without => [
            decade => '1970',
        ],
        -literal => [
            'and[or][year][]' => '2015',
            'and[or][year][]' => '2014',
            'and[and][or][primary_collection][]' => 'TAPUHI',
            'and[and][or][primary_collection][]' => 'Public Address',
        ]
    },

The C<-and>, C<-or>, and C<-without> subfields are converted into the relevant
forms in the URL query. If this isn't sufficient, you can use C<-literal> and
work it out yourself. These will be URI-escaped and just shoved one after the
other into the query parameters. Be careful if you mix these different methods
up.

Boolean fields are recognised and Perl-truth is converted into API-truth.

Paging should be handled by your application code.

The result is a Perl structure that reflects the response from the API.

If there is an error, an exception is thrown.

=cut

sub search {
    my ( $self, %args ) = @_;

    my $filters = $self->_build_filters( $args{filters} ) if $args{filters};
    delete $args{filters};

    # This is the only boolean except in filters
    if ( exists $args{exclude_filters_from_facets} ) {
        $args{exclude_filters_from_facets} = $args{exclude_filters_from_facets} ? 'true' : 'false';
    }

    my @params =
      map { uri_escape_utf8($_) . '=' . uri_escape_utf8( $args{$_} ) } keys %args;
    push @params, @$filters if $filters;

    # Build our URL
    my $url = URI->new( $self->base_url . 'records.json' );
    if (@params) {
        my $pstr = join( '&', @params );
        $url->query($pstr);
    }

    my $ua  = LWP::UserAgent->new( agent => $self->useragent, );
    my $req = HTTP::Request->new(
        'GET' => $url,
        [
            'Accept' => 'application/json; charset=UTF-8',
            $self->api_key ? ( 'Authentication-Token' => $self->api_key ) : (),
        ]
    );
    my $res = $ua->simple_request($req);
    if ( !$res->is_success ) {
        croak "Unsuccessful response from DigitalNZ API: " . $res->status_line . "\n";
    }

    my $json    = JSON::MaybeXS->new( utf8 => 1 );
    my $content = $json->decode( $res->decoded_content );
    return $content;
}

# Parses our filter structure out into a set of URL parameters
sub _build_filters {
    my ( $self, $filters ) = @_;

    my @out;
    my %is_boolean;
    $is_boolean{$_} = 1 foreach (qw( is_commercial_use has_lat_lng ));

    foreach my $type (qw( and or without )) {
        if ( exists $filters->{ '-' . $type } ) {
            foreach my $and ( pairs $filters->{ '-' . $type }->@* ) {
                my ( $k, $v ) = @$and;
                if ( $is_boolean{$k} ) {
                    push @out, $type . '[' . $k . '][]=' . ( $v ? 'true' : 'false' );
                } else {
                    push @out, $type . '[' . $k . '][]=' . uri_escape_utf8( $v );
                }
            }
        }
    }
    push @out, $filters->{-literal}->@* if $filters->{-literal};
    return \@out;
}

=head2 metadata

    my $record = $dnz->metadata(
        record_id => 123456,
        fields => [qw( title description creator collection_title )],
    );

Fetches the record information (metadata) for an individual record. You may
specify the fields you're interested in, see the DigitalNZ documentation for
more information. You can also say 'default' or 'verbose'.

If there is an error, an exception is thrown.

=cut

sub metadata {
    my ( $self, %args ) = @_;

    my $record_id = delete $args{record_id};
    my $fields    = delete $args{fields};

    croak "'record_id' is a required paramater to Net::DigitalNZ::V3->metadata\n"
      unless defined $record_id;

    my $url = URI->new( $self->base_url . 'records/' . $record_id . '.json' );

    if ($fields) {
        $url->query_param( fields => $fields );
    }

    my $ua  = LWP::UserAgent->new( agent => $self->useragent, );
    my $req = HTTP::Request->new(
        'GET' => $url,
        [
            'Accept' => 'application/json; charset=UTF-8',
            $self->api_key ? ( 'Authentication-Token' => $self->api_key ) : (),
        ]
    );
    my $res = $ua->simple_request($req);
    if ( !$res->is_success ) {
        croak "Unsuccessful response from DigitalNZ API: " . $res->status_line . "\n";
    }

    my $json    = JSON::MaybeXS->new( utf8 => 1 );
    my $content = $json->decode( $res->decoded_content );
    return $content;
}

sub sets {
    confess 'sets support is not implemented.';
}

sub more_like_this {

    # Only documented in the swagger, but an interesting feature
    confess 'more_like_this is not implemented.';
}

has api_key => ( is => 'ro', );

has base_url => (
    is      => 'ro',
    default => 'https://api.digitalnz.org/v3/',
);

has useragent => (
    is      => 'ro',
    default => "Net::DigitalNZ::V3/$Net::DigitalNZ::V3::VERSION (Perl)",
);

=head1 AUTHOR

Robin Sheat, C<< <rsheat at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Robin Sheat.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

1;

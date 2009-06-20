package Net::DigitalNZ;

use warnings;
use strict;
use URI::Escape;
use JSON::Any 1.19;

use Data::Dumper;

our $VERSION = '0.01';

# <hash>
# <results type="array">
# <result>
# <category>Images</category>
# <metadata-url>http://api.digitalnz.org/records/v1/58961</metadata-url>
# <title>Wellington Public Hospital, Newtown, Wellington</title>
# <date></date>
# <source-url>http://api.digitalnz.org/records/v1/58961/source</source-url>
# <content-provider>Alexander Turnbull Library</content-provider>
# <id>58961</id>
# <description>Wellington Public Hospital, Newtown, Wellington, photographed by the Burton Brothers in the 1880s.</description>
# <syndication-date>2009-03-25T03:10:20.067Z</syndication-date>
# <display-url>http://timeframes.natlib.govt.nz/logicrouter/servlet/LogicRouter?PAGE=object&amp;OUTPUTXSL=object.xslt&amp;pm_RC=REPO02DB&amp;pm_OI=7784&amp;pm_GT=Y&amp;pm_IAC=Y&amp;api_1=GET_OBJECT_XML&amp;num_result=0&amp;Object_Layout=viewimage_object</display-url>
# <thumbnail-url>http://digital.natlib.govt.nz/get/31209?profile=thumb</thumbnail-url>
# </result>

# curl "http://api.digitalnz.org/records/v1.xml/?api_key=...&search_text=wellington" | less

sub search {
    my $self = shift;
    my $api_key = shift;
    my $query = shift;
    my $params = shift || {};

    #grab the params
    my $num_results = $params->{'num_results'} || 10;
    my $start = $params->{'start'} || 1;
    my $sort = $params->{'sort'} || undef;


    #build URL
    my $url = 'http://api.digitalnz.org/records/v1.xml/?'
            .'search_text='. URI::Escape::uri_escape($query)
            .'&api_key='. URI::Escape::uri_escape($api_key);

#$url .= '&lang=' . URI::Escape::uri_escape($lang) if ($lang);

    #do request
    my $req = $self->{ua}->get($url);

    die 'Failed to connect to api.digitalnz.org' unless $req->is_success;
    return [] if $req->content eq 'null';

    #decode the json
    my $res = JSON::Any->jsonToObj($req->content) ;

    print Dumper($res);
    return $res->{'results'};

}


1;

=head1 NAME

Net::Digitalnz Search 

=head1 SYNOPSYS

  use Net::Digitalnz;

  my $digitalnz = Net::Digitalnz::Search->new();

  my $results = $digitalnz->search('Waitangi');
  foreach my $r (@{ $results }) {
    my $speaker =  $r->{from_user};
    my $text = $r->{text};
    my $time = $r->{created_at};
    print "$time <$speaker> $text\n";
  }

   #you can also use any methods from Net::Twitter.
   my $digitalnz = Net::Twitter::Search->new(username => $username, password => $password);
   my $steve = $digitalnz->search('Steve');
   $digitalnz->update($steve .'? Who is steve?');
    
=head1 DESCRIPTION

For searching twitter - handy for bots

=head1 METHOD

=head2 search 

required parameter: query

returns: hash

=head1 EXAMPLES

Find tweets containing a word

  $results = $digitalnz->search('word');

Find tweets from a user:

  $results = $digitalnz->search('from:br3nda');

Find tweets to a user:

  $results = $digitalnz->search('to:serenecloud');

Find tweets referencing a user:

  $results = $digitalnz->search('@br3ndabot');

Find tweets containing a hashtag:

  $results = $digitalnz->search('#perl');

Combine any of the operators together:

  $results = $digitalnz->search('solaris anger from:br3nda');

 
=head1 ADDITIONAL PARAMETERS 

  The search method also supports the following optional URL parameters:
 
=head2 lang

Restricts tweets to the given language, given by an ISO 639-1 code.

  $results = $digitalnz->search('hello', {lang=>'en'});
  #search for hello in maori
  $results = $digitalnz->search('kiaora', {lang=>'mi'});


=head2 rpp

The number of tweets to return per page, up to a max of 100.

  $results = $digitalnz->search('love', {rpp=>'10'});

=head2 page

The page number to return, up to a max of roughly 1500 results (based on rpp * page)

  #get page 3
  $results = $digitalnz->search('love', {page=>'3'});

=head2 since_id

Returns tweets with status ids greater than the given id.

  $results = $digitalnz->search('love', {since_id=>'1021356410'});

=head2 geocode

returns tweets by users located within a given radius of the given latitude/longitude, where the user's location is taken from their Twitter profile. The parameter value is specified by "latitide,longitude,radius", where radius units must be specified as either "mi" (miles) or "km" (kilometers).

 $results = $digitalnz->search('coffee', {geocode=> '40.757929,-73.985506,25km'});

Note that you cannot use the near operator via the API to geocode arbitrary locations; however you can use this geocode parameter to search near geocodes directly.


=head1 SEE ALSO

L<Net::Twitter>

=head1 AUTHOR

Brenda Wallace <shiny@cpan.org>

=cut

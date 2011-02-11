use strict;
use utf8;
use warnings;

package WWW::Brettspielnetz;

=encoding utf8

=head1 NAME

WWW::Brettspielnetz - Web-Client für L<http://www.brettspielnetz.de>

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.12';

use Encode qw(decode);
use Net::Netrc;
use Readonly;
use URI;
use URI::Escape qw(uri_unescape);
use Web::Scraper qw(process scrape);
use WWW::Brettspielnetz::Spiel;
use base 'WWW::Mechanize';
use namespace::clean;

Readonly::Scalar my $FALSE  => '';
Readonly::Scalar my $SERVER => 'http://www.brettspielnetz.de';
Readonly::Hash my %Faktor =>
  ( Stunde => 3600, Stunden => 3600, Tag => 86400, Tage => 86400 );

# Wir rufen die einfach direkt auf:
Readonly::Scalar my $URI_AM_ZUG => '/ajax/gameslist1.php';

{
    my $scraper;

    sub am_zug {
        my $self = shift;
        my $attempts;

        # Seite holen:
        {
            $self->get( $SERVER . $URI_AM_ZUG );
            last if $self->content !~ /Melde dich neu an!/;
            die $self->_errmsg('Login war nicht erfolgreich')
              if ++$attempts > 1;
            $self->login;
            redo;
        }

        # Ergebnis analysieren:
        my ( $anzahl_spiele, $html ) = split /\|/, $self->content, 2;
        die $self->_errmsg('Unerwarteter Inhalt') if $anzahl_spiele !~ /^\d+\z/;
        return unless $anzahl_spiele;
        $scraper //= scraper {
            process table => process
              tr          => 'spiele[]',
              scraper {
                process td => 'td[]' => 'TEXT';

                # Den CSS-Selector 'td[align="center"][width=30]'
                # versteht die Library offenbar nicht.
                process 'td[align="center"]' => process a => uri_spiel =>
                  '@href';
                process td => process 'a[href=~"user"]' => uri_gegner =>
                  '@href';
              };
        };
        my $data = $scraper->scrape($html);

        # {
        #   spiele => [
        #     {
        #       uri_spiel => "/halali/play.php?gamenumber=4711",
        #       uri_gegner => "/user.php?username=fany",
        #       td => ["", "fany\xA0", "\xA0Halali\xA0(6 Tage, Z22)"],
        #     },
        #     {
        #       uri_spiel => "/en+garde/play.php?gamenumber=45815",
        #       uri_gegner => "/user.php?username=foo",
        #       td => ["", "foo\xA0", "\xA0En Garde\xA0(4 Tage, Z11)"],
        #     },
        #     {
        #       uri_spiel => "/en+garde/play.php?gamenumber=162342",
        #       uri_gegner => "/user.php?username=bar",
        #       td => ["", "bar\xA0", "\xA0En Garde\xA0(4 Tage, Z4)"],
        #     },
        #   ],
        # }
        die $self->_errmsg( @{ $data->{spiele} }
              . " statt $anzahl_spiele Spiel"
              . ( $anzahl_spiele != 1 && 'e' )
              . ' gefunden' )
          if @{ $data->{spiele} } != $anzahl_spiele;

        my $time = time;
        map {
            my %spiel;
            ( $spiel{nr} ) = $_->{uri_spiel} =~ /gamenumber=(\d+)/
              or die $self->_errmsg( 'Unbekannte Spiel-URI', $_->{uri_spiel} );

            $spiel{uri} = URI->new_abs( $_->{uri_spiel}, $self->uri );

            $spiel{gegner}{uri} = URI->new_abs( $_->{uri_gegner}, $self->uri );

            $_->{uri_gegner} =~ /username=([^=]+)/
              or die $self->_errmsg( 'Unbekannte Mitspieler-URI',
                $_->{uri_gegner} );
            $spiel{gegner}{username} =
              decode( $self->res->content_charset, uri_unescape($1) );
            die $self->_errmsg( 'Inkonsistente Gegner-Daten ("'
                  . $spiel{gegner}{username}
                  . '" vs. "'
                  . $_->{td}[1]
                  . '") bei Spiel '
                  . $spiel{nr} )
              if "$spiel{gegner}{username} " ne $_->{td}[1];

            ( $spiel{name}, my $anzahl, my $einheit, my $ow, $spiel{zugnr} ) =
              $_->{td}[2] =~ /
                  ^
                  \ ?
                  (.*?)
                  \ \(
                  (\d+)
                  \ 
                  (${\ join '|', map quotemeta, keys %Faktor })
                  ,
                  (\ oW,)?
                  \ Z
                  (\d+)
                  \)
                  \z
              /ox
              or die $self->_errmsg( 'Ungültige Spieldetaildaten ("'
                  . $_->{td}[2]
                  . '") bei Spiel '
                  . $spiel{nr} );

            $spiel{ow} = defined $ow;

            $spiel{timeout} = $time + $anzahl * $Faktor{$einheit};

            WWW::Brettspielnetz::Spiel->new( \%spiel );
        } @{ $data->{spiele} };
    }
}

sub _errmsg {
    my $self = shift;
    join "\n", @_, grep defined, $self->uri, $self->content;
}

sub login {
    ( my $self = shift )->get( $SERVER . '/' );
    my $uri = URI->new($SERVER) or die;
    ( my $mach = Net::Netrc->lookup( $uri->host ) )
      or die 'Keine Logindaten für ' . $uri->host . ' gefunden';
    $self->set_visible( $mach->lpa )
      or die $self->_errmsg('Angeben der Logindaten nicht erfolgreich');
    $self->click;
    die $self->_errmsg('Login war nicht erfolgreich')
      unless $self->find_link( text => $mach->login );
    return;
}

1;

__END__

=head1 SYNOPSE

    use WWW::Brettspielnetz;
    my @am_zug = WWW::Brettspielnetz->new->am_zug;
    print 'Du bist ',
          @am_zug ? map( 'in ' . $_->name .
                         ' gegen ' . $_->gegner . ' ',
                         @am_zug )
                  : 'nicht ',
          "am Zug.\n";

=head1 BESCHREIBUNG

Dieses Modul kann sich für Dich auf L<http://www.brettspielnetz.de> einloggen
und herausfinden, bei welchen Spielen Du am Zug bist.
Deine Zugangsdaten werden dabei Deinem C<~/.netrc> entnommen, sprich da sollte
ungefähr Folgendes drinstehen:

    machine www.brettspielnetz.de
        login foo
        password bar

=head1 METHODEN

=over 4

=item am_zug

Liefert eine Liste von L<Spielen|WWW::Brettspielnetz::Spiel>, bei denen Du
gerade am Zug ist.
Falls die Liste leer ist, dann nicht aufgrund eines Fehlers - in diesem Fall
würde das Modul nämlich L<sterben|perlfunc/die> -, sondern weil Du eben gerade
nirgends dran bist.

=item login

Meldet sich für Dich auf L<http://www.brettspielnetz.de> an.
Brauchst Du aber eigentlich gar nicht aufrufen, weil L</am_zug> das (nur) bei
Bedarf automagisch tut.

=back

=head1 AUTOR

Martin H. Sluka, <fany@cpan.org>

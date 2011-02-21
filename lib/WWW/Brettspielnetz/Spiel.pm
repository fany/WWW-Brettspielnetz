use strict;
use utf8;
use warnings;

package WWW::Brettspielnetz::Spiel;

=encoding utf8

=head1 NAME

WWW::Brettspielnetz::Spiel - repräsentiert ein Spiel auf brettspielnetz.de

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.14';

use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use URI;
use WWW::Brettspielnetz::Mitspieler;
use namespace::clean -except => 'meta';

use constant Abk2Name => {
    'Carc. - Burg' => 'Carcassonne - Die Burg',
    'Käsekäst.'    => 'Käsekästchen',
    'Kodekn.'      => 'Kodeknacker',
    'Schiffe v.'   => 'Schiffe versenken',
    'Würfelsp.'    => 'Würfelspiel',
};

subtype __PACKAGE__ . '::URI' => as class_type('URI');
coerce __PACKAGE__ . '::URI' => from Str => via sub { URI->new(shift) };

subtype __PACKAGE__ . '::Name' => as 'Str' => where { !exists Abk2Name->{$_} };
coerce __PACKAGE__ . '::Name' => from 'Str' => via { Abk2Name->{$_} };

has 'bar' => (
    isa    => 'ModStr',
    is     => 'rw',
    coerce => 1,
);

has gegner => (
    is     => 'ro',
    isa    => 'WWW::Brettspielnetz::Mitspieler',
    coerce => 1,
);

# Könnte man evtl. zu einem eigenen Objekttyp ausbauen:
has name => (
    is     => 'ro',
    isa    => __PACKAGE__ . '::Name',
    coerce => 1,
);

has nr => (
    is  => 'ro',
    isa => 'Int',
);

has ow => (
    is  => 'ro',
    isa => 'Bool',
);

has timeout => (
    is  => 'ro',
    isa => 'Int',
);

has uri => (
    is     => 'ro',
    isa    => __PACKAGE__ . '::URI',
    coerce => 1,
);

has zugnr => (
    is  => 'ro',
    isa => 'Int',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 SYNOPSE

    use WWW::Brettspielnetz::Spiel;
    my $spiel = WWW::Brettspielnetz::Spiel->new(
        name    => 'Ur',
        gegner  => { username => 'fany' },
        nr      => 4711,
        timeout => time + 86400,
        uri     => 'http://www.brettspielnetz.de/ur/play.php?gamenumber=4711',
        zugnr   => 42,
    );

=head1 BESCHREIBUNG

Jedes Objekt dieser Klasse repräsentiert eine Partie auf brettspielnetz.de.
In einem String-Kontext gibt das Objekt automagisch den Benutzernamen aus.

=head1 ATTRIBUTE

Alle Attribute müssen bereits beim Anlegen des Objekts angegeben und können
danach nur noch abgefragt werden.

=over 4

=item name

Name des Spiels

=item nr

eindeutige Nummer für dieses Spiel

=item uri

URL, unter der Du das Spiel zum Spielen aufrufen kannst, als L<URI>-Objekt
(das ggf. automagisch aus einem String generiert wird)

=item ow

Spiel ohne Wertung?

=item zugnr

aktuelle Zugnummer

=item timeout

Zeitpunkt (als Epoch-Wert), zu dem spätestens der nächste Zug erfolgen muss

=back

=head1 AUTOR

Martin H. Sluka, <fany@cpan.org>

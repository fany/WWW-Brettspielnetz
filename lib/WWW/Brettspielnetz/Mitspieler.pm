use strict;
use utf8;
use warnings;

package WWW::Brettspielnetz::Mitspieler;

=encoding utf8

=head1 NAME

WWW::Brettspielnetz::Mitspieler - repräsentiert einen Spieler auf brettspielnetz.de

=head1 VERSION

Version 0.15

=cut

our $VERSION = '0.01';

use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use URI;
use namespace::clean -except => 'meta';

use overload '""' => sub { shift->username };

coerce __PACKAGE__, from HashRef => via sub { __PACKAGE__->new(shift) };
subtype __PACKAGE__.'::URI' => as class_type('URI');
coerce __PACKAGE__ . '::URI', from Str => via sub { URI->new(shift) };

has uri => (
    is      => 'ro',
    isa     => __PACKAGE__ . '::URI',
    lazy    => 1,
    default => sub {
        URI->new( 'http://www.brettspielnetz.de/user.php?username='
              . shift->username );
    },
    coerce => 1,
);

has username => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=head1 SYNOPSE

    use WWW::Brettspielnetz::Spieler;
    my $spieler = WWW::Brettspielnetz::Spieler->new(
        username => 'fany',
        uri      => 'http://www.brettspielnetz.de/user.php?username=fany',
    );

=head1 BESCHREIBUNG

Jedes Objekt dieser Klasse repräsentiert einen Benutzer auf brettspielnetz.de.
In einem String-Kontext gibt das Objekt automagisch den Benutzernamen aus.

=head1 ATTRIBUTE

Alle Attribute müssen bereits beim Anlegen des Objekts angegeben und können
danach nur noch abgefragt werden.

=over 4

=item username

Benutzername des Spielers

=item uri

URL der Seite mit Informationen über den Mitspieler

=item 

=back

=head1 AUTOR

Martin H. Sluka, <fany@cpan.org>

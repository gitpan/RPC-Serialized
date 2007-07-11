#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/networks/src/debian/packages/libr/librpc-serialized-perl/trunk/t/45-rpc-serialized-acl-group-file.t $
# $LastChangedRevision: 1323 $
# $LastChangedDate: 2007-07-09 17:10:19 +0100 (Mon, 09 Jul 2007) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 33;

use URI::file;
use File::Temp 'tempfile';

use_ok('RPC::Serialized::ACL::Group::File');
can_ok( 'RPC::Serialized::ACL::Group::File', 'new' );
can_ok( 'RPC::Serialized::ACL::Group::File', 'path' );
can_ok( 'RPC::Serialized::ACL::Group::File', 'is_member' );
can_ok( 'RPC::Serialized::ACL::Group::File', 'match' );

eval { RPC::Serialized::ACL::Group::File->new() };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, 'Missing or invalid URI' );

eval { RPC::Serialized::ACL::Group::File->new('garbage') };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, 'Missing or invalid URI' );

eval { RPC::Serialized::ACL::Group::File->new( URI->new('garbage') ) };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, 'Missing or invalid URI' );

eval {
    RPC::Serialized::ACL::Group::File->new( URI->new('http://www.example.org/') );
};
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, 'Missing or invalid URI' );

eval { RPC::Serialized::ACL::Group::File->new( URI->new('file://') ) };
isa_ok( $@, 'RPC::Serialized::X::Application' );
is( $@->message, "Can't determine path from URI file://" );

my $group
    = RPC::Serialized::ACL::Group::File->new( URI::file->new('/no/such/file') );
isa_ok( $group, 'RPC::Serialized::ACL::Group' );
isa_ok( $group, 'RPC::Serialized::ACL::Group::File' );
can_ok( $group, 'path' );
is( $group->path, '/no/such/file' );
eval { $group->is_member('foo') };
isa_ok( $@, 'RPC::Serialized::X::System' );
is( $@->message, "Failed to open /no/such/file: No such file or directory" );

my ( $fh, $path ) = tempfile( UNLINK => 1 );
$fh->print(<<'EOT');
foo
bar
baz
EOT
$fh->close();

$group = RPC::Serialized::ACL::Group::File->new( URI::file->new($path) );
isa_ok( $group, 'RPC::Serialized::ACL::Group' );
isa_ok( $group, 'RPC::Serialized::ACL::Group::File' );
is( $group->path, $path );
foreach my $u (qw(foo bar baz)) {
    ok( $group->is_member($u) );
    ok( $group->match($u) );
}
ok( not $group->is_member('quux') );
ok( not $group->match('quux') );
ok( not $group->match() );

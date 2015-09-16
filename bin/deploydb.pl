#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use DB::CGSchema;
use Getopt::Long;

my ($preversion, $mode, $dbname, $dbhost, $dbuser, $dbpass, $dbtype) = ('', '', 'news_data', 'localhost', 'mmp', 'mmp', 'Pg');
GetOptions(
	'p|preversion:s'  => \$preversion,
	'm|mode:s' => \$mode,
	'n|name:s' => \$dbname,
	'a|addr:s' => \$dbhost,
	'u|user:s' => \$dbuser,
	'p|pass:s' => \$dbpass,
	't|type:s' => \$dbtype,
) or die "Can't get options from command line";

die "Unknown mode '$mode'"
	if($mode and $mode ne 'init' and $mode ne 'upgrade');

my $schema = DB::CGSchema->connect("dbi:$dbtype:dbname=$dbname;host=$dbhost", $dbuser, $dbpass);

if($mode eq 'init') {
	print "Initializing...\n";
	my $sql_dir = "$FindBin::Bin/../migrations/cg";
	my $version = $schema->schema_version();
	$schema->create_ddl_dir('PostgreSQL', $version, $sql_dir, $preversion);
	print "done!\n";
	exit 0;
}

if(!$schema->get_db_version()) {
	print "Deploying...\n";
	$schema->deploy();
	print "done!\n";
} else {
	print "Upgrading...\n";
	$schema->upgrade();
	print "done!\n";
}

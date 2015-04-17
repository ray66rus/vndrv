#!/usr/bin/perl -w
# 
# Copyright (c) Broadcast.me, 2003-2013
#
# Broadcas.me Production driver module
#

package VN::Driver;
use strict;

use vars qw($VERSION);
$VERSION = "3.1";

use FindBin qw( $Bin );
use lib $Bin; 
use Carp qw( cluck confess );
use VN::Client;
use Encode;

#
# interface
#

sub new
{
	my $proto = shift();
	my $addr = shift() // 'localhost';
	my $port = shift() // 9898;

	my $class = ref($proto) || $proto;
	my $self = {
		'addr' => $addr,
		'port' => $port,
		'last' => -1,
		'rundown' => {},
		'archive' => {},
		'dst_obj' => {},
		'updateList' => {},
		'_b_firstupdate' => 1,
		'_vn_client' => undef,
		'_vn_protocol_version' => 0,
		_is_active => 0,
	};
	bless ($self, $class);
	return $self;
}

sub init {
	my $self = shift;

	$self->{addr} = shift
		if @_;
	$self->{port} = shift
		if @_;

	VN::Client::Init() || confess("Can't initialize VN::Client#");
	my $vn = VN::Client->new;
	$self->{'_vn_client'} = $vn;
	$vn->OpenConnection($self->{addr}, $self->{port}) || confess("Can't open connection to $self->{addr}:$self->{port}#");
	$self->{_is_active} = 1;
}

sub is_active {
	my $self = shift;
	return $self->{_is_active};
}

sub _print_log {
	my $self = shift;
	open( LOG, ">>:utf8", "$Bin/../log/VNDriver.log" );
	print LOG `date "+%D %T"`." ".join("\n", @_)."\n";
	close LOG;

	return 0;
}

sub SetHandlers
{
	my $self = shift;

	my $obj = shift();
	confess('First argument for SetHandlers should be an object#')
		unless(ref($obj) =~ /\:{2}/);
	$self->{dst_obj} = $obj;
	for(qw(Rundown Issue Story Block Archive))
	{
		last unless(@_);
		$self->{"OnUpdate$_"} = shift;
	}
}

sub DESTROY
{
	my $self = shift();
#	VN::Client::CloseConnection();
	if( defined($self->{'_vn_client'}) ) {
		$self->{'_vn_client'}->CloseConnection();
	}
}

sub _check_connection {
	my $self = shift();

	if(!$self->{'_vn_client'}->CheckConnection()) {
        	return 0 unless $self->{'_vn_client'}->OpenConnection($self->{addr}, $self->{port});
		$self->{'last'} = -1;
		$self->{'_vn_protocol_version'} = 0;
	}	
	return 1;
}

sub Sync {
	my $self = shift();
	my $update = shift || '';
	my $flags  = shift || {};

	my $res = 'ERROR';
	my $retry_count = 0;
	while( $retry_count < 3 && $res ) {
		$retry_count++;
		unless( $update ) {
			unless( defined($flags->{noUpdate}) ) {
				$res = $self->_sync(undef);   
			}
		} else {
			$res = $self->_sync($update,  'no_update');   
			unless( defined($flags->{noUpdate}) ) {
				$self->_sync(undef,  'no_update');
			}
		}
	}
	if( $update && !defined($flags->{noUpdate}) ) {
		$self->_call_subscribers();	
	}
	return $res;
}


sub _get_protocol_version {
	my $self = shift();

	$self->_print_log("get_protocol_version. Caller:".(caller())[0].":".(caller())[2]);

	my $res = $self->{'_vn_client'}->Call("get_protocol_version");
	if( $res ) {
		chomp $res;
		$self->{'_vn_protocol_version'} = $res;
	} else {
		$self->{'_vn_protocol_version'} = 1;
	}

	$self->_print_log("result: $res");

	return $self->{'_vn_protocol_version'};
}

sub _sync {
	my $self = shift();
	my $update = shift || '';
	my $no_update = shift;
	my $res;
	
	return 'ERROR no connection to server' unless( $self->_check_connection() );

	unless( $self->{'_vn_protocol_version'} ) {
		return 'ERROR _vn_protocol_version is undef' unless( $self->_get_protocol_version() );
	}

# $self->{'_vn_protocol_version'} >=  2.5 :)
	if($update) {
		my $send = $self->{last}."\n".$update;
		$res = $self->{'_vn_client'}->Call("arabesque_put_delta_v2", $send);
		$res = decode("utf8", $res);
		return '' if(substr($res, 0, 2) eq 'OK' );
	} else {
		$res = $self->{'_vn_client'}->Call("arabesque_get_delta_v2", $self->{last});
		$res = decode("utf8", $res);
	}

	if($update) {
		if(substr($res, 0, 5) eq 'ERROR' ) {
			$res =~ tr/\r//d;
			$res = substr($res, 6);
			return $res;
		}
	}

	return 'ERROR Unexpected result' unless($res);
	$res =~ tr/\r//d;

	return 'ERROR Unexpected result' unless($res =~ s/^(\d+)\n//s ); 
	$self->{last} = $1;
 
	my @objects = split(/\n#\n/s, $res);

	$self->{'_b_noupdate'} = ($self->{'_b_firstupdate'} or 
		(defined($no_update) and $no_update) );

	for my $ob (@objects)
	{
		$self->parse_object($ob);
	}

	if($self->{'_b_firstupdate'}) {
		if(!(defined($no_update) and $no_update)) {
			$self->_call_subscribers;
		}
		$self->{'_b_firstupdate'} = 0;
	}

	return '';
}


#
# implementation
#
sub parse_object {
	my ($self, $object) = @_;

	my @lines = split(/\n/s, $object);

	return unless($lines[0] =~ /^(.+?):(.*?)$/);

	# get type
	my $type = $1;

	# parse path
	@_ = split('/',$2);
	my $path = {
		'issue' => 0,
		'story' => 0,
		'block' => 0,
	};

	for(@_) {
		/^(.+?):(\d+)$/;
		$path->{$1} = $2;
	}

	# parse keywords
	my $data = {};
	for my $i (1..$#lines)
	{
    		if($lines[$i] =~ /^(.+?):(.*)$/)
	    	{
	    		$data->{$1} = $2;
		}
	}

	# call handler
#	return unless(grep {$_ eq $type} qw/rundown issue story block/);
	return unless(grep {$_ eq $type} qw/rundown archive issue story block/);
	eval '$self->update_'.$type.'($path, $data)';
	cluck($@) if($@);
}

sub update_archive {
	my ($self, $path, $data) = @_;

	# delete expired issues
	if(exists $data->{issues})
	{
		my @archive_update = split(',', $data->{issues});
		my @archive = keys %{$self->{archive}};

		for my $issue (@archive)
		{
			unless(grep {$_ eq $issue} @archive_update)
			{
				delete $self->{archive}->{$issue};
			}
		}
		for my $issue (@archive_update) {
			$self->{archive}->{$issue} = 1;
		}
	}
	if(exists($self->{OnUpdateArchive}) and $self->{OnUpdateArchive}) {
		if($self->{'_b_noupdate'}) {
			$self->{updateList}{'archive'} = 1;
		} else {
			&{$self->{OnUpdateArchive}}($self->{dst_obj}, $path, $data);
		}
	}
}

sub update_rundown {
	my ($self, $path, $data) = @_;

	# delete expired issues
	if(exists $data->{issues})
	{
		my @rundown_update = split(',', $data->{issues});
		my @rundown = keys %{$self->{rundown}};

		for my $issue (@rundown)
		{
			unless(grep {$_ eq $issue} @rundown_update)
			{
				delete $self->{rundown}->{$issue};
			}
		}
	}

	# call user handler
#	if(exists($self->{OnUpdateRundown}) 
#		and $self->{OnUpdateRundown}
#		and !$self->{'_b_firstupdate'})
#	{
#		&{$self->{OnUpdateRundown}}($self->{dst_obj}, $path);
#	}
	# call user handler
	if(exists($self->{OnUpdateRundown}) and $self->{OnUpdateRundown}) {
		if($self->{'_b_noupdate'}) {
			$self->{updateList}{0} = $data;
		} else {
			&{$self->{OnUpdateRundown}}($self->{dst_obj}, $path, $data);
		}
	}
}

sub update_issue {
	my ($self, $path, $data) = @_;

	my $id = $path->{issue};

	# create issue if not found
	my $issue;
	if(exists $self->{rundown}->{$id})
	{
		$issue = $self->{rundown}->{$id};
	}
	else
	{
		$issue = {
			'PATH'		=> $path,
			'CHLD'		=> {},
			'slug'		=> '',
			'begin'		=> 0,
			'chrono'	=> 0,
		};
		$self->{rundown}->{$id} = $issue;
	}

	# delete expired stories
	if(exists $data->{stories})
	{
		my @stories_update = split(',', $data->{stories});
		my @stories = keys %{$issue->{CHLD}};

		for my $story (@stories)
		{
			unless(grep {$_ eq $story} @stories_update)
			{
				delete $issue->{CHLD}->{$story};
			}
		}
	}

	# copy data fields
	for(keys %$data)
	{
		$issue->{$_} = $data->{$_};
	}

	# call user handler
	if(exists($self->{OnUpdateIssue}) and $self->{OnUpdateIssue} ) {
		if($self->{'_b_noupdate'}) {
			$self->{updateList}{$path->{issue}} = $data;
		} else {
			&{$self->{OnUpdateIssue}}($self->{dst_obj}, $path, $data);
		}
	}
}

sub update_story {
	my ($self, $path, $data) = @_;

	# find issue
	unless(exists $self->{rundown}->{$path->{issue}})
	{
		$self->{last} = -1;
		$self->{'_b_firstupdate'} = 1;
		cluck("issue not found");
	}
	my $issue = $self->{rundown}->{$path->{issue}};

	# create story if not found
	my $story;
	if(exists $issue->{CHLD}->{$path->{story}})
	{
		$story = $issue->{CHLD}->{$path->{story}};
	}
	else
	{
		$story = {
			'PATH'		=> $path,
			'CHLD'		=> {},
			'slug'		=> '',
			'active'	=> 1,
			'position'	=> 0,
		};
        $issue->{CHLD}->{$path->{story}} = $story;
	}

	# delete expired blocks
	if(exists $data->{blocks})
	{
		my @blocks_update = split(',', $data->{blocks});
		my @blocks = keys %{$story->{CHLD}};

		for my $block (@blocks)
		{
			unless(grep {$_ eq $block} @blocks_update)
			{
				delete $story->{CHLD}->{$block};
			}
		}
	}

	# copy data fields
	for(keys %$data)
	{
		$story->{$_} = $data->{$_};
	}

	# call user handler
	if(exists($self->{OnUpdateStory}) and $self->{OnUpdateStory} ) {
		if($self->{'_b_noupdate'}) {
			$self->{updateList}{$path->{story}} = $data;
		} else {
			&{$self->{OnUpdateStory}}($self->{dst_obj}, $path, $data);
		}
	}
}

sub update_block {
	my ($self, $path, $data) = @_;

	# find issue
	unless(exists $self->{rundown}->{$path->{issue}})
	{
		$self->{last} = -1;
		$self->{'_b_firstupdate'} = 1;
		cluck("issue not found");
	}
	my $issue = $self->{rundown}->{$path->{issue}};

	# find story
	unless(exists $issue->{CHLD}->{$path->{story}})
	{
		$self->{last} = -1;
		$self->{'_b_firstupdate'} = 1;
		cluck("story not found");
	}
	my $story = $issue->{CHLD}->{$path->{story}};

	# create block if not found
	my $block;
	if(exists $story->{CHLD}->{$path->{block}})
	{
		$block = $story->{CHLD}->{$path->{block}};
	}
	else
	{
		$block = {
			'PATH'		=> $path,
			'slug'		=> '',
			'active'	=> 1,
			'position'	=> 0,
		};
        $story->{CHLD}->{$path->{block}} = $block;
	}

	# copy data fields
	for(keys %$data)
	{
		$block->{$_} = $data->{$_};
	}

	# call user handler
	if(exists($self->{OnUpdateBlock}) and $self->{OnUpdateBlock} ) {
		if($self->{'_b_noupdate'}) {
			$self->{updateList}{$path->{block}} = $data;
		} else {
			&{$self->{OnUpdateBlock}}($self->{dst_obj}, $path, $data);
		}
	}
}

# call update handler for all objects
sub _call_subscribers {
	my $self = shift;

	# call user handler for rundown
	my $path = { 'issue' => 0, 'story' => 0, 'block' => 0 };
	if(exists($self->{OnUpdateRundown}) and $self->{OnUpdateRundown})
	{
		if( exists($self->{updateList}{0}) ) {
			&{$self->{OnUpdateRundown}}($self->{dst_obj}, $path, $self->{updateList}{0});
		}
	}
#	$path = { 'issue' => 0, 'story' => 0, 'block' => 0 };
	if(exists($self->{OnUpdateArchive}) and $self->{OnUpdateArchive})
	{
		if( exists($self->{updateList}{'archive'}) ) {
			&{$self->{OnUpdateArchive}}($self->{dst_obj}, $path)
		}
	}

	# call update for every element in the object tree
	my @rundown = keys %{$self->{rundown}};
	for my $issue (@rundown)
	{
		# call user handler for issue
		$path = { 'issue' => $issue, 'story' => 0, 'block' => 0 };
		if(exists($self->{OnUpdateIssue}) and $self->{OnUpdateIssue})
		{
			if( exists($self->{updateList}{$issue}) ) {
				&{$self->{OnUpdateIssue}}($self->{dst_obj}, $path, $self->{updateList}{$issue});
			}
		}

		my $current_issue = $self->{'rundown'}{$issue};
		my @stories = keys %{$current_issue->{'CHLD'}};
		for my $story (@stories)
		{
			# call user handler for story
			$path = { 'issue' => $issue, 'story' => $story, 'block' => 0 };
			if(exists($self->{'OnUpdateStory'}) and $self->{'OnUpdateStory'})
			{
				if( exists($self->{updateList}{$story}) ) {
					&{$self->{OnUpdateStory}}($self->{dst_obj}, $path, $self->{updateList}{$story});
				}
			}
			my $current_story = $current_issue->{'CHLD'}{$story};
			my @blocks = keys %{$current_story->{'CHLD'}};
			for my $block (@blocks)
			{
				# call user handler for block
				$path = { 'issue' => $issue, 'story' => $story, 'block' => $block };
				if(exists($self->{'OnUpdateBlock'}) and $self->{'OnUpdateBlock'})
				{
					if( exists($self->{updateList}{$block}) ) {
						&{$self->{OnUpdateBlock}}($self->{dst_obj}, $path, $self->{updateList}{$block});
					}
				}
			}
		}
	}
	$self->{updateList} = {};
}

1;


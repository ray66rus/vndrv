#!/usr/bin/env perl

use Modern::Perl;

use constant VERSION => "0.1.0";

use threads;
use Thread::Queue;
use threads::shared;

use Encode qw( encode decode );
use Socket;
use Log::Handler;
use Log::Handler::Output::File;
use FindBin qw ( $Bin );
use Config::JSON;
use Time::HiRes qw( usleep );

use lib "$Bin/../lib";
use VNDRV::VNPeer;

# log
our $LOG;
our $LOG_LEVEL;

# CFG
my $CFG;

#IPC
my $IS_RUNNING :shared;
my %VN_DATA :shared;
my $VN_CHANGES;

################
# main
#
eval {
	init_config();
	init_log();
	init_ipc();
	start_vn_connector();
	while($IS_RUNNING) { sleep(1) }
};
if($@) {
	print "Fatal error: $@\n";
	exit 1;
}
exit 0;
################

sub init_config {
	my $filename = "$Bin/../conf/vndrv.json";
	die "File not found: $filename"
		unless -f $filename;
	$CFG = Config::JSON->new($filename);
}

sub init_log {
	mkdir "$Bin/../log"
		unless -d "$Bin/../log";
	$LOG = Log::Handler->new(file => {
			filename => "$Bin/../log/vndrv.log",
			utf8 => 1,
			minlevel => 'critical',
			maxlevel => $CFG->get('log/level') || 'info',
			mode	=> 'append',
			fileopen => 0,
			reopen	=> 0,
			timeformat => '%d.%m.%Y %H:%M:%S',
			message_layout => '%T %P %m',
			newline	=> 1,
		}
	);
	$LOG->info(sprintf("NUD0000I ===== VN Driver version %s started =====", VERSION));
}

sub init_ipc {
	$IS_RUNNING = 1;
	%VN_DATA = ();
	$VN_CHANGES = Thread::Queue->new;
	$SIG{$_} = 'IGNORE'
		for(keys %SIG);
	$SIG{INT} = sub { cleanup(); exit(0) }
}

sub start_vn_connector {
	my $vn_client = new VNDRV::VNPeer({
		changes => $VN_CHANGES,
		data => \%VN_DATA,
		is_application_running => \$IS_RUNNING,
		log => $LOG,
		config => $CFG,
	});
	return
		if defined(threads->create({context => 'void'}, \&VNDRV::VNPeer::run, $vn_client));
	cleanup();
	$LOG->crit("NUD0001F Can't start process for Broadcast.me News connector");
	die "Can't start News connector";
}

sub cleanup {
	$SIG{INT} = 'IGNORE';
	_stop_all_threads();
	$LOG->info(sprintf("NUD0003I ===== VN Driver version %s stopped =====", VERSION));
}

sub _stop_all_threads {
	$IS_RUNNING = 0;

	$LOG->info('NUD0002I waiting for all threads to stop');
	my @running_threads = threads->list(threads::running);
	for my $thr (@running_threads) {
		$thr->kill('STOP');
	}
	while(1) {
		my @running_threads = threads->list(threads::running);
		my @joinable_threads = threads->list(threads::joinable);
		last
			if(@joinable_threads == 0 and @running_threads == 0);
		for my $thr (@joinable_threads) {
			$thr->join();
		}
		usleep(10000);		
	}
}



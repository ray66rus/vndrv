package VNDRV::VNPeer;

use Moose;
use threads;
use threads::shared;
use Time::HiRes qw ( usleep gettimeofday tv_interval );

has 'changes' => (is => 'ro', isa => 'Thread::Queue');
has 'data' => (is => 'ro', isa => 'HashRef');
has 'is_application_running' => (is => 'ro', isa => 'ScalarRef');
has 'log' => (is => 'ro', isa => 'Log::Handler');
has 'config' => (is => 'ro', isa => 'Config::JSON');

has 'rd' => (is => 'ro', isa => 'HashRef', default => sub { {} });
has 'drv' => (is => 'ro', isa => 'VN::Driver', default => sub { require VN::Driver; return new VN::Driver });

sub run {
	my $self = shift;

	$self->log->info("NUD0004I Broadcast.me News connector started");

	$self->_set_stop_thread_signal_handler;

	my $sync_interval = $self->config->get('news/sync_interval') // 4;
	eval {	
		while(!$self->_is_terminated) {
			$self->_sync_VN;
			sleep $sync_interval;
		}
	};
	$self->log->error("NUD0005F Critical error in News peer: $@")
		if($@);
	$self->log->debug("NUD0006I Exit from News peer thread");
}

sub _set_stop_thread_signal_handler {
	my $self = shift;
	$SIG{STOP} = sub { threads->exit };
}

sub _is_terminated {
	my $self = shift;
	return (${$self->is_application_running} == 1) ? 0 : 1;
}

sub _sync_VN {
	my $self = shift;
	my $arg  = shift;
	my $flags= shift || {};
	
	my $drv = $self->drv;
	$self->_init_driver
		unless $drv->is_active;

	return "VN::Driver is not initialized"
		unless $drv->is_active;

	my $res;
	eval {
		if($arg) {
			$res = $drv->Sync($arg, $flags);
		} else {
			$res = $drv->Sync(undef, $flags);
		}
	};
	$res = $@
		if($@);

	return $res;
}

sub _init_driver {
	my $self = shift;

	my $drv = $self->drv;
	eval {
		$drv->init($self->config->get('news/host') // 'localhost', 
				$self->config->get('news/port') // 9898);
	};
	if($@) {
		$self->log->crit("NUD0007F Can't initialize News Driver: $@");
		return undef;
	}
	$drv->SetHandlers($self, 
		\&on_update_rundown, 
		\&on_update_issue,
		\&on_update_story,
		\&on_update_block,
	);
	return $drv;
}

sub _add_changes_to_queue {
	my $self = shift;
	my $changes = shift;
	$self->changes->enqueue($changes);
}

sub on_update_rundown {
	my ($self, $path, $data) = @_;
	print "update rundown $data\n";
}

sub on_update_issue {
	my ($self, $path, $data) = @_;
	print "update issue $path $data\n";
}

sub on_update_story {
	my ($self, $path, $data) = @_;
	print "update story $path $data\n";
}

sub on_update_block {
	my ($self, $path, $data) = @_;
	print "update block $path $data\n";
}

1;


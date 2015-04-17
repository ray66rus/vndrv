package VNDRV::VNPeer;

use Moose;
use threads;
use threads::shared;
use Storable qw( dclone );
use Hash::Merge;

has 'changes_queue' => (is => 'ro', isa => 'Thread::Queue');
has 'data' => (is => 'ro', isa => 'HashRef');
has 'is_application_running' => (is => 'ro', isa => 'ScalarRef');
has 'log' => (is => 'ro', isa => 'Log::Handler');
has 'config' => (is => 'ro', isa => 'Config::JSON');

has 'rd' => (is => 'ro', isa => 'HashRef', default => sub { { issues => {} } });
has 'drv' => (is => 'ro', isa => 'VN::Driver', default => sub { require VN::Driver; new VN::Driver });
has 'merger' => (is => 'ro', isa => 'Hash::Merge', default => sub { Hash::Merge->new });
has 'changes' => (is => 'rw', isa => 'HashRef', default => sub { {} });


sub run {
	my $self = shift;

	$self->log->info("NUD0004I Broadcast.me News connector started");

	$self->_set_stop_thread_signal_handler;

	my $sync_interval = $self->config->get('news/sync_interval') // 4;
	eval {	
		while(!$self->_is_terminated) {
			$self->_clear_changes;
			$self->_sync_VN;
			$self->_add_changes_to_queue;
			sleep $sync_interval;
		}
	};
	$self->log->error("NUD0005F Critical error in News peer: $@")
		if($@);
	$self->log->debug("NUD0006I Exit from News peer thread");
	$self->_send_termination_signal;
}

sub _set_stop_thread_signal_handler {
	my $self = shift;
	$SIG{STOP} = sub { threads->exit };
}

sub _is_terminated {
	my $self = shift;
	return (${$self->is_application_running} == 1) ? 0 : 1;
}

sub _send_termination_signal {
	my $self = shift;
	${$self->is_application_running} = 0;
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

	$self->log->error("NUD0009E News sync error #$res")
		if $res;

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

sub _clear_changes {
	my $self = shift;
	$self->changes({});
}

sub _add_changes_to_queue {
	my $self = shift;
	$self->changes_queue->enqueue($self->_get_changes_clone);
}

sub on_update_rundown {
	my ($self, $path, $data) = @_;

	my $current_issues = $self->_issues;
	my @updated_issues_ids = split(/,/, $data->{issues});
	for my $i_id (keys %$current_issues) {
		$self->_delete_issue($i_id)
			unless grep { $_ eq $i_id } @updated_issues_ids;
	}
	for my $i_id (@updated_issues_ids) {
		$self->_add_empty_issue($i_id)
			unless defined($current_issues->{$i_id})
	}
}

sub _issues {
	my $self = shift;
	return $self->rd->{issues};
}

sub _delete_issue {
	my $self = shift;
	my $id = shift;

	my $issues = $self->_issues;
	delete $issues->{$id};
	$self->_merge_change({rd => {issues => {$id => ''}}});
}

sub _merge_change {
	my $self = shift;
	my $change = shift;
	$self->changes($self->merger->merge(
			$self->changes, $change
		)
	);
}

sub _add_empty_issue {
	my $self = shift;
	my $id = shift;

	my $issues = $self->_issues;
	$issues->{$id} = {};
	$self->_merge_change({rd => {issues => {$id => {}}}});
}

sub on_update_issue {
	my ($self, $path, $data) = @_;
#	print "update issue $path $data\n";
}

sub on_update_story {
	my ($self, $path, $data) = @_;
#	print "update story $path $data\n";
}

sub on_update_block {
	my ($self, $path, $data) = @_;
#	print "update block $path $data\n";
}

sub _get_changes_clone {
	my $self = shift;
	return dclone($self->changes);
}


1;
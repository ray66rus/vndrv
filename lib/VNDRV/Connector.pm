package VNDRV::Connector;

use Moose;
use threads;
use Storable qw( dclone );

has 'queue' => (is => 'ro', isa => 'Thread::Queue');
has 'rd' => (is => 'ro', isa => 'HashRef');
has 'data_lock' => (is => 'ro', isa => 'ScalarRef');
has 'is_application_running' => (is => 'ro', isa => 'ScalarRef');
has 'log' => (is => 'ro', isa => 'Log::Handler');
has 'config' => (is => 'ro', isa => 'HashRef');

sub run {
	my $self = shift;

	my $name = ref($self);
	$self->log->info("NUD0010I $name connector started");

	$self->_set_stop_thread_signal_handler;
	eval {	
		while(!$self->_is_terminated) {
			if(defined(my $changes = $self->queue->dequeue_timed(1))) {
				$self->_process_changes($changes);
			}
		}
	};
	$self->log->error("NUD0011E Critical error in $name connector: $@")
		if($@);
	$self->log->debug("NUD0012I Exit from $name connector thread");
}

sub _set_stop_thread_signal_handler {
	my $self = shift;
	$SIG{STOP} = sub { threads->exit };
}

sub _is_terminated {
	my $self = shift;
	return (${$self->is_application_running} == 1) ? 0 : 1;
}

sub get_issue {
	my $self = shift;
	my $path = shift;

	lock(${$self->data_lock});
	my $issue = $self->rd->{issues}{$path->{issue}};
	return dclone($issue);
}

sub get_story {
	my $self = shift;
	my $path = shift;

	lock(${$self->data_lock});
	my $story = '';
	eval {
		my $issue = $self->rd->{issues}{$path->{issue}};
		$story = $issue->{stories}{$path->{story}};
	};
	return $story;
}

sub get_block {
	my $self = shift;
	my $path = shift;

	lock(${$self->data_lock});
	my $block = '';
	eval {
		my $issue = $self->rd->{issues}{$path->{issue}};
		my $story = $issue->{stories}{$path->{story}};
		$block = $story->{blocks}{$path->{block}};
	};
	return $block;
}

1;
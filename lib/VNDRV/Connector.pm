package VNDRV::Connector;

use Moose;
use threads;

has 'queue' => (is => 'ro', isa => 'Thread::Queue');
has 'rd' => (is => 'ro', isa => 'HashRef');
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

	lock(%{$self->rd});
	my $issue = $self->rd->{issues}{$path->{issue}};
	return $issue ? $self->_copy_from_shared($issue) : '';
}

sub _copy_from_shared {
	my $self = shift;
	my $data = shift;

	my $ref = ref($data);
	if($ref eq 'HASH') {
		return $self->_copy_hash_from_shared($data);
	} elsif($ref eq 'ARRAY') {
		return $self->_copy_array_from_shared($data);
	} elsif($ref eq 'SCALAR') {
		return $self->_copy_scalar_from_shared($data);
	} elsif(!$ref) {
		return $data;
	}
	return undef;
}

sub _copy_hash_from_shared {
	my $self = shift;
	my $hsh = shift;

	my %res = ();
	$res{$_} = $self->_copy_from_shared($hsh->{$_}) for (keys %$hsh);
	return \%res;
}

sub _copy_array_from_shared {
	my $self = shift;
	my $arr = shift;

	my @res = ();
	push @res, $self->_copy_from_shared($_) for @$arr;
	return \@res;
}

sub _copy_scalar_from_shared {
	my $self = shift;
	my $sclr = shift;
	return $self->_copy_from_shared($$sclr);
}

sub get_story {
	my $self = shift;
	my $path = shift;

	lock(%{$self->rd});
	my $story = '';
	eval {
		my $issue = $self->rd->{issues}{$path->{issue}};
		$story = $issue->{stories}{$path->{story}};
	};
	return $story ? $self->_copy_from_shared($story) : '';
}

sub get_block {
	my $self = shift;
	my $path = shift;

	lock(%{$self->rd});
	my $block = '';
	eval {
		my $issue = $self->rd->{issues}{$path->{issue}};
		my $story = $issue->{stories}{$path->{story}};
		$block = $story->{blocks}{$path->{block}};
	};
	return $block ? $self->_copy_from_shared($block) : '';
}

1;
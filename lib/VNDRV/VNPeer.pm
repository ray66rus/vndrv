package VNDRV::VNPeer;

use Moose;
use threads;
use threads::shared;
use Hash::Merge;
use Data::Dumper;

has 'changes_queues' => (is => 'ro', isa => 'HashRef');
has 'rd' => (is => 'ro', isa => 'HashRef');
has 'feedback' => (is => 'ro', isa => 'Thread::Queue');
has 'is_application_running' => (is => 'ro', isa => 'ScalarRef');
has 'log' => (is => 'ro', isa => 'Log::Handler');
has 'config' => (is => 'ro', isa => 'HashRef');

has 'drv' => (is => 'ro', isa => 'VN::Driver', default => sub { require VN::Driver; new VN::Driver });
has 'merger' => (is => 'ro', isa => 'Hash::Merge', default => sub { Hash::Merge->new });
has 'changes' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'max_feedback_size' => (is => 'rw', isa => 'Int', default => 10);

sub run {
	my $self = shift;

	$self->log->info("NUD0004I Broadcast.me News connector started");

	$self->_set_stop_thread_signal_handler;
	my $sync_interval = $self->config->{sync_interval} // 4;
	eval {	
		$self->_init_rundown;
		while(!$self->_is_terminated) {
			$self->_clear_changes;
			my $feedback = $self->_get_feedback;
			$self->_sync_VN($feedback);
			$self->_add_changes_to_queues;
			sleep $sync_interval;
		}
	};
	$self->log->error("NUD0005F Critical error in News connector: $@")
		if($@);
	$self->log->debug("NUD0006I Exit from News connector thread");
	$self->_send_termination_signal;
}

sub _set_stop_thread_signal_handler {
	my $self = shift;
	$SIG{STOP} = sub { threads->exit };
}

sub _init_rundown {
	my $self = shift;

	$self->max_feedback_size($self->config->{max_feedback_size})
		if $self->config->{max_feedback_size};
	lock(%{$self->rd});
	$self->rd->{issues} = shared_clone({});
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
		lock(%{$self->rd});
		$res = $drv->Sync($arg ? $arg : undef, $flags);
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
		$drv->init($self->config->{host} // 'localhost', 
				$self->config->{port} // 9898);
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

sub _add_changes_to_queues {
	my $self = shift;

	my $changes = $self->changes; 
	return
		unless %$changes;
	for my $queue (values %{$self->changes_queues}) {
		$queue->enqueue($changes);
	}
}

sub _get_feedback {
	my $self = shift;

	my $feedback = {};
	my $counter = 0;
	while($counter++ < $self->max_feedback_size and defined(my $msg = $self->feedback->dequeue_nb)) {
		$feedback = $self->merger->merge($msg, $feedback);
	}
	return
		unless %$feedback;

	$self->log->debug('NUD0017I Got feedback #' . Data::Dumper->Dump([$feedback]));
	return $self->_translate_feedback_to_text($feedback);
}

sub _translate_feedback_to_text {
	my $self = shift;
	my $feedback = shift;

	my @res = ();
	for my $i_id (keys %{$feedback->{issues}}) {
		my $issue = $feedback->{issues}{$i_id};
		push @res, "issue:issue:$i_id";
		$self->_add_object_fields_to_feedback($issue, \@res, 'stories');
		push @res, '#';
		$self->_add_issue_stories_to_feedback($issue, "issue:/$i_id", \@res);
	}
	my $res = join("\n", @res) . "\n";
	$self->log->debug("NUD0018I Sending feedback to news #$res");
	return $res;
}

sub _add_object_fields_to_feedback {
	my $self = shift;
	my $object = shift;
	my $res = shift;
	my $exclude_field = shift;	

	for my $field_id (keys %$object) {
		push @$res, "$field_id:$object->{$field_id}"
			unless $exclude_field and $field_id eq $exclude_field;
	}
}

sub _add_issue_stories_to_feedback {
	my $self = shift;
	my $issue = shift;
	my $path = shift;
	my $res = shift;

	return
		unless $issue->{stories};
	for my $s_id (keys %{$issue->{stories}}) {
		my $story = $issue->{stories}{$s_id};
		push @$res, "story:$path/story:$s_id";
		$self->_add_object_fields_to_feedback($story, $res, 'blocks');
		push @$res, '#';
		$self->_add_story_blocks_to_feedback($story, "$path/story:$s_id", $res);
	}
}

sub _add_story_blocks_to_feedback {
	my $self = shift;
	my $story = shift;
	my $path = shift;
	my $res = shift;

	return
		unless $story->{blocks};
	for my $b_id (keys %{$story->{blocks}}) {
		my $block = $story->{blocks}{$b_id};
		push @$res, "block:$path/block:$b_id";
		$self->_add_object_fields_to_feedback($block, $res);
		push @$res, '#';
	}	
}

sub on_update_rundown {
	my ($self, $path, $data) = @_;

	$self->_update_list({
			current_list => [ keys %{$self->_issues} ],
			updated_list => [ split(/,/, $data->{issues}) ],
			add_func => \&_add_empty_issue,
			delete_func => \&_delete_issue
		});
}

sub _issues {
	my $self = shift;
	return $self->rd->{issues};
}

sub _update_list {
	my $self = shift;
	my $params = shift;

	my @current_list = @{$params->{current_list}};
	my @updated_list = @{$params->{updated_list}};
	my $add_func = $params->{add_func};
	my $delete_func = $params->{delete_func};
	my @options = @{$params->{options} // []};

	for my $id (@current_list) {
		$self->$delete_func($id, @options)
			unless grep { $_ eq $id } @updated_list;
	}
	for my $id (@updated_list) {
		$self->$add_func($id, @options)
			unless grep { $_ eq $id } @current_list;
	}	
}

sub _delete_issue {
	my $self = shift;
	my $id = shift;

	my $issues = $self->_issues;
	delete $issues->{$id};
	$self->_merge_change({issues => {$id => ''}});
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
	$issues->{$id} = shared_clone({id => $id, stories => {}});
	$self->_merge_change({issues => {$id => {}}});
}

sub on_update_issue {
	my ($self, $path, $data) = @_;

	my $issue = $self->_issue($path);
	return
		unless $issue;
	$self->_update_issue_fields($issue, $data);
	$self->_update_issue_stories($issue, $data);
}

sub _issue {
	my $self = shift;
	my $path = shift;
	return $self->_issues->{$path->{issue}};
}

sub _update_issue_fields {
	my $self = shift;
	my $issue = shift;
	my $data = shift;

	my %change = $self->_get_change_hash($issue, $data, 'stories');
	$self->_merge_change({issues => {$issue->{id} => \%change}});
}

sub _get_change_hash {
	my $self = shift;
	my $object = shift;
	my $data = shift;
	my $exception_field = shift;

	my %change = ();
	for my $field_id (keys %$data) {
		next
			if $exception_field and $field_id eq $exception_field;
		my $old = $object->{$field_id};
		my $new = $object->{$field_id} = $data->{$field_id};
		$change{$field_id} = {new => $new};
		$change{$field_id}{old} = $old
			if defined($old);
	}
	return %change;
}


sub _update_issue_stories {
	my $self = shift;
	my $issue = shift;
	my $data = shift;

	my $stories = $data->{stories};
	return
		unless $stories;
	$self->_update_list({
			current_list => [ keys %{$issue->{stories} // {}} ],
			updated_list => [ split(/,/, $stories) ],
			add_func => \&_add_empty_story,
			delete_func => \&_delete_story,
			options => [ $issue ],
		});
}

sub _add_empty_story {
	my $self = shift;
	my $id = shift;
	my $issue = shift;

	$self->_merge_change({issues => {$issue->{id} => {stories => {$id => {id => $id}}}}});
	$issue->{stories}{$id} = shared_clone({id => $id, blocks => {}});
}

sub _delete_story {
	my $self = shift;
	my $id = shift;
	my $issue = shift;

	delete $issue->{stories}{$id};
	$self->_merge_change({issues => {$issue->{id} => {stories => {$id => ''}}}});
}

sub on_update_story {
	my ($self, $path, $data) = @_;

	my %objects = (issue => $self->_issue($path), story => $self->_story($path));
	return
		unless $objects{issue} and $objects{story};
	$self->_update_story_fields(\%objects, $data);
	$self->_update_story_blocks(\%objects, $data);
}

sub _story {
	my $self = shift;
	my $path = shift;

	my $issue = $self->_issue($path);
	return undef
		unless $issue;
	return $issue->{stories}{$path->{story}};
}

sub _update_story_fields {
	my $self = shift;
	my $objects = shift;
	my $data = shift;

	my ($issue, $story) = ($objects->{issue}, $objects->{story});
	my %change = $self->_get_change_hash($story, $data, 'blocks');
	$self->_merge_change({issues => {$issue->{id} => {stories => {$story->{id} => \%change}}}});
}

sub _update_story_blocks {
	my $self = shift;
	my $objects = shift;
	my $data = shift;

	my $blocks = $data->{blocks};
	return
		unless $blocks;
	my ($issue, $story) = ($objects->{issue}, $objects->{story});
	$self->_update_list({
			current_list => [ keys %{$story->{blocks}} ],
			updated_list => [ split(/,/, $blocks) ],
			add_func => \&_add_empty_block,
			delete_func => \&_delete_block,
			options => [ $issue, $story ],
		});
}

sub _add_empty_block {
	my $self = shift;
	my $id = shift;
	my $issue = shift;
	my $story = shift;

	$story->{blocks}{$id} = shared_clone({id => $id});
	$self->_merge_change({
		issues => {
			$issue->{id} => {
				stories => {
					$story->{id} => {
						blocks => {$id => {id => $id}}
					}
				}
			}
		}
	});
}

sub _delete_block {
	my $self = shift;
	my $id = shift;
	my $issue = shift;
	my $story = shift;

	delete $story->{blocks}{$id};
	$self->_merge_change({
		issues => {
			$issue->{id} => {
				stories => {
					$story->{id} => {
						blocks => {$id => ''}
					}
				}
			}
		}
	});
}

sub on_update_block {
	my ($self, $path, $data) = @_;

	my %objects = (
		issue => $self->_issue($path),
		story => $self->_story($path),
		block => $self->_block($path)
	);
	return
		unless $objects{issue} and $objects{story} and $objects{block};
	$self->_update_block_fields(\%objects, $data);
}

sub _block {
	my $self = shift;
	my $path = shift;

	my $story = $self->_story($path);
	return undef
		unless $story;
	return $story->{blocks}{$path->{block}};
}

sub _update_block_fields {
	my $self = shift;
	my $objects = shift;
	my $data = shift;

	my ($issue, $story, $block) = ($objects->{issue}, $objects->{story}, $objects->{block});
	my %change = $self->_get_change_hash($block, $data);
	$self->_merge_change({
		issues => {
			$issue->{id} => {
				stories => {
					$story->{id} => {
						blocks => {$block->{id} => \%change}
					}
				}
			}
		}
	});
}

1;
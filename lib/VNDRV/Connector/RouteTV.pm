package VNDRV::Connector::RouteTV;

use Moose;

extends 'VNDRV::Connector';

has 'published_issues' => (is => 'ro', isa => 'HashRef', default => sub { {} });

sub BUILD {
	my $self = shift;
	die "Mandatory parameter 'url' not found"
		unless $self->config->{url};
}

sub _process_changes {
	my $self = shift;
	my $changes = shift;

	my $changed_issues = $changes->{issues};
	for my $i_id (keys %$changed_issues) {
		my $issue_delta = $changed_issues->{$i_id};
		if(!$issue_delta or $self->_is_publish_cancelled($issue_delta)) {
			$self->_delete_issue($i_id);
		} elsif($self->_is_just_published($issue_delta)) {
			$self->_add_issue($i_id);
			$self->_update_playlist($i_id);
		} elsif($self->_is_published($i_id) and $self->_does_change_affects_playlist($issue_delta)) {
			$self->_update_playlist($i_id);
		}
	}
}

sub _is_publish_cancelled {
	my $self = shift;
	my $issue = shift;
	return defined($issue->{publish_state}) ? ($issue->{publish_state}{new} ? 0 : 1) : 0;
}

sub _is_just_published {
	my $self = shift;
	my $issue = shift;
	return defined($issue->{publish_state}) ? $issue->{publish_state}{new} : 0;
}

sub _is_published {
	my $self = shift;
	my $id = shift;
	return defined($self->published_issues->{$id});
}

sub _delete_issue {
	my $self = shift;
	my $id = shift;
	delete $self->published_issues->{$id};
}

sub _add_issue {
	my $self = shift;
	my $id = shift;

	return
		if $self->_is_published($id);
	$self->published_issues->{$id} = 1;
}

sub _does_change_affects_playlist {
	my $self = shift;
	my $change = shift;

	return 1
		if $change->{slug} or $change->{begin} or $change->{end};
	for my $s_id (keys %{$change->{stories} // {}}) {
		my $story = $change->{stories}{$s_id};
		return 1
			if !$story or $story->{slug} or $story->{active};
		for my $b_id (keys %{$story->{blocks} // {}}) {
			my $block = $story->{blocks}{$b_id};
			return 1
				if !$block or $block->{active} or $block->{slug} or $block->{clip_id} or $block->{format_id};
		}
	}
	return 0;
}

sub _update_playlist {
	my $self = shift;
	my $id = shift;

	eval {
		my $playlist = $self->_generate_playlist($id);
		die "Issue '$id' not found"
			unless $playlist;
		$self->log->debug("NUD0014I Playlist for issue '$id' created #" . Data::Dumper->Dump([$playlist]));

		my $url = $self->config->{url};
		my $req_result = $self->ua->post($url, {data => $self->json->encode($playlist)});
		die "Can't request $url"
			unless $req_result->is_success;

		my $reply = $self->json->decode($req_result->decoded_content);
		die $reply->{message}
			unless $reply->{status} eq 'success';
	};
	if($@) {
		$self->log->warn("NUD0015W Failed to publish issue '$id' #$@");
		$self->send_feedback({issues => {$id => {publish_state => 0}}});
	} else {
		$self->log->debug("NUD0016I Issue '$id' was published");
		$self->send_feedback({issues => {$id => {publish_state => 1}}});
	}
}

sub _generate_playlist {
	my $self = shift;
	my $id = shift;

	my $issue = $self->get_issue({issue => $id});
	if(!$issue) {
		$self->log->warn("NUD0016W Issue '$id' not found");
		return '';
	}
	return ''
		unless $issue;
	my @stories = ();
	for my $s_id ($self->_sort_by_position($issue->{stories})) {
		my $story = $issue->{stories}{$s_id};
		next
			unless $story->{active};
		if($story->{type} eq 'ads') {
			my $story_desc = pop @stories // [];
			push @$story_desc, { type => 'ads', slug => $story->{slug} };
			push @stories, $story_desc;
			next;
		}
		my @story_descr = ();
		for my $b_id ($self->_sort_by_position($story->{blocks})) {
			my $block = $story->{blocks}{$b_id};
			next
			        unless $block->{active};
			my $format = $block->{format_id};
			if($format eq 'DEC' or $format eq 'PKG') {
			        push @story_descr, {
			                clip => $block->{clip_id},
			                type => 'cnt',
			                slug => $block->{slug}
			        }
			}
		}
		push @stories, \@story_descr;
	}
	return { issue_id => $issue->{id},
	        issue_name => $issue->{slug},
	        timeframe_begin => ($issue->{begin} / 1000),
	        timeframe_end => ($issue->{end} / 1000),
	        stories => \@stories
	}
}

sub _sort_by_position {
	my $self = shift;
	my $objects = shift;
	return sort { ($objects->{$a}{position} // 0) <=> ($objects->{$b}{position} // 0)} (keys %$objects);
}

1;
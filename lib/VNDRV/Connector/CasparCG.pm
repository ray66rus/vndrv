package VNDRV::Connector::CasparCG;

use Moose;

use DB::CGSchema;

extends 'VNDRV::Connector';

has 'db' => (is => 'ro', isa => 'Schema');
has 'data' => (is => 'ro', isa => 'DB::CGSchema::Result::Main');

sub BUILD {
	my $self = shift;

	my $db_config = $self->config->{db} // {};
	my $addr = $db_config->{addr} // 'localhost';
	my $user = $db_config->{user} // 'mmp';
	my $pass = $db_config->{pass} // 'mmp';
	my $sql_driver = $db_config->{db_type} // 'Pg';
	my $dbname = $db_config->{name} // 'news_data';

	$self->{db} = DB::CGSchema->connect("dbi:$sql_driver:dbname=$dbname;host=$addr", $user, $pass);
	$self->{data} = $self->{db}->resultset('Main');
	$self->data->delete_all;
	$self->data->create({issue_id => 0, story_id => 0, block_id => 0, last => \'NOW()'});
}

sub _process_changes {
	my $self = shift;
	my $changes = shift;

	my $changed_issues = $changes->{issues};
	for my $i_id (keys %$changed_issues) {
		$self->_process_issue_changes($i_id, $changed_issues->{$i_id});
	}
}

sub _process_issue_changes {
	my $self = shift;
	my $i_id = shift;
	my $issue_delta = shift;

	eval {
		if(!$issue_delta or _is_issue_air_flag_removed($issue_delta)) {
			$self->_remove_issue($i_id);
		} elsif(_is_issue_air_falg_added($issue_delta)) {
			$self->_add_issue($i_id);
		} elsif(_is_significant_issue_field_changed($issue_delta)) {
			$self->_update_issue_data($i_id, $issue_delta);
		}
	};
	$self->log->error("NUD0020E Error while updating issue $i_id: $@")
		if $@;
}

sub _is_issue_air_flag_removed {
	my $issue_data = shift;
	return (defined($issue_data->{type}) and $issue_data->{type}{new} ne 'active') ? 1 : 0;
}

sub _remove_issue {
	my $self = shift;
	my $i_id = shift;

	$self->data->search({issue_id => $i_id})->delete_all;
	$self->data->find({issue_id => 0, story_id => 0, block_id => 0}, {key => 'path'})->update({last => \'NOW()'});
}

sub _is_issue_air_falg_added {
	my $issue_data = shift;
	return (defined($issue_data->{type}) and $issue_data->{type}{new} eq 'active') ? 1 : 0;
}

sub _add_issue {
	my $self = shift;
	my $i_id = shift;

	my $issue = $self->get_issue({issue => $i_id});
	my $slug = $issue->{slug};
	$self->data->find({issue_id => 0, story_id => 0, block_id => 0}, {key => 'path'})->update({last => \'NOW()'});
	$self->data->update_or_create({issue_id => $i_id, issue_slug => $slug, story_id => 0, block_id => 0, last => \'NOW()'});
	for my $s_id (keys %{$issue->{stories}}) {
		my $story = $issue->{stories}{$s_id};
		next
			unless $story->{active};
		$self->_add_story({
				issue_id => $i_id,
				story_id => $s_id,
				issue => $issue
		});
	}
}

sub _is_significant_issue_field_changed {
	my $issue_data = shift;
	return (defined($issue_data->{slug}) or defined($issue_data->{stories})) ? 1 : 0;
}

sub _update_issue_data {
	my $self = shift;
	my $i_id = shift;
	my $issue_delta = shift;

	my $issue = $self->get_issue({issue => $i_id});
	return
		unless _is_air_issue($issue);

	$self->data->search({issue_id => $i_id})->update({issue_slug => $issue->{slug}, last => \'NOW()'})
		if defined($issue_delta->{slug});

	my $changed_stories = $issue_delta->{stories};
	return
		unless defined($changed_stories);

	for my $s_id (keys %$changed_stories) {
		$self->_process_story_changes({
			issue_id => $i_id,
			story_id => $s_id,
			story_delta => $changed_stories->{$s_id},
			issue => $issue
		});
	}
}

sub _is_air_issue {
	my $issue = shift;
	return $issue->{type} eq 'active' ? 1 : 0;
}

sub _process_story_changes {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $story_delta, $issue) =
		($params->{issue_id}, $params->{story_id}, $params->{story_delta}, $params->{issue});

	eval {
		if(!$story_delta or _is_story_active_flag_just_unset($story_delta)) {
			$self->_remove_story($i_id, $s_id);
		} elsif(_is_story_active_flag_just_set($story_delta)) {
			$self->_add_story($params);
		} elsif(_is_significant_story_field_changed($story_delta)) {
			$self->_update_story_data($params);
		}
	};
	$self->log->error("NUM0021E Error while updating story $s_id: $@")
		if $@;
}

sub _is_story_active_flag_just_unset {
	my $story_data = shift;
	return (defined($story_data->{active}) and !$story_data->{active}{new}) ? 1 : 0;
}

sub _remove_story {
	my $self = shift;
	my ($i_id, $s_id) = @_;

	$self->data->search({issue_id => $i_id, story_id => $s_id})->delete_all;
	$self->data->find({issue_id => $i_id, story_id => 0, block_id => 0}, {key => 'path'})->update({last => \'NOW()'});
}

sub _is_story_active_flag_just_set {
	my $story_data = shift;
	return (defined($story_data->{active}) and $story_data->{active}{new}) ? 1 : 0;
}

sub _add_story {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $issue) =
		($params->{issue_id}, $params->{story_id}, $params->{issue});

	my $story = $issue->{stories}{$s_id};
	$self->data->find({issue_id => $i_id, story_id => 0, block_id => 0}, {key => 'path'})->update({last => \'NOW()'});
	$self->data->update_or_create({
		issue_id => $i_id,
		issue_slug => $issue->{slug},
		story_id => $s_id,
		story_slug => $story->{slug},
		block_id => 0,
		last => \'NOW()'
	});
	for my $b_id (keys %{$story->{blocks}}) {
		my $block = $story->{blocks}{$b_id};
		next
			unless $block->{active};
		$self->_add_block({
				issue_id => $i_id,
				story_id => $s_id,
				block_id => $b_id,
				issue => $issue
		});
	}
}

sub _is_significant_story_field_changed {
	my $story_data = shift;
	return (defined($story_data->{slug}) or defined($story_data->{blocks})) ? 1 : 0;
}

sub _update_story_data {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $story_delta, $issue) =
		($params->{issue_id}, $params->{story_id}, $params->{story_delta}, $params->{issue});

	my $story = $issue->{stories}{$s_id};
	return
		unless $story->{active};

	$self->data->search({issue_id => $i_id, story_id => $s_id})->update({story_slug => $story->{slug}, last => \'NOW()'})
		if defined($story_delta->{slug});

	my $changed_blocks = $story_delta->{blocks};
	return
		unless defined($changed_blocks);

	for my $b_id (keys %$changed_blocks) {
		$self->_process_block_changes({
			issue_id => $i_id,
			story_id => $s_id,
			block_id => $b_id,
			block_delta => $changed_blocks->{$b_id},
			issue => $issue
		});
	}
}

sub _add_block {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $b_id, $issue) =
		($params->{issue_id}, $params->{story_id}, $params->{block_id}, $params->{issue});

	my $story = $issue->{stories}{$s_id};
	my $block = $story->{blocks}{$b_id};
	$self->data->find({issue_id => $i_id, story_id => $s_id, block_id => 0}, {key => 'path'})->update({last => \'NOW()'});
	$self->data->update_or_create({
		issue_id => $i_id,
		issue_slug => $issue->{slug},
		story_id => $s_id,
		story_slug => $story->{slug},
		block_id => $b_id,
		block_slug => $block->{slug},
		captions => $self->_get_captions($block->{text}),
		last => \'NOW()'
	});
}

sub _process_block_changes {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $b_id, $block_delta, $issue) =
		($params->{issue_id}, $params->{story_id}, $params->{block_id}, $params->{block_delta}, $params->{issue});

	eval {
		if(!$block_delta or _is_block_active_flag_just_unset($block_delta)) {
			$self->_remove_block($i_id, $s_id, $b_id);
		} elsif(_is_block_active_flag_just_set($block_delta)) {
			$self->_add_block($params);
		} elsif(_is_significant_block_field_changed($block_delta)) {
			$self->_update_block_data($params);
		}
	};
	$self->log->error("NUM0022E Error while updating block $b_id: $@")
		if $@;
}

sub _is_block_active_flag_just_unset {
	my $block_data = shift;
	return (defined($block_data->{active}) and !$block_data->{active}{new}) ? 1 : 0;
}


sub _is_block_active_flag_just_set {
	my $block_data = shift;
	return (defined($block_data->{active}) and $block_data->{active}{new}) ? 1 : 0;
}

sub _is_significant_block_field_changed {
	my $block_data = shift;
	return (defined($block_data->{slug}) or defined($block_data->{text})) ? 1 : 0;
}

sub _remove_block {
	my $self = shift;
	my ($i_id, $s_id, $b_id) = @_;

	$self->data->search({issue_id => $i_id, story_id => $s_id, block_id => $b_id})->delete_all;
	$self->data->find({issue_id => $i_id, story_id => $s_id, block_id => 0}, {key => 'path'})->update({last => \'NOW()'});
}

sub _update_block_data {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $b_id, $block_delta, $issue) =
		($params->{issue_id}, $params->{story_id}, $params->{block_id}, $params->{block_delta}, $params->{issue});

	my $story = $issue->{stories}{$s_id};
	my $block = $story->{blocks}{$b_id};
	return
		unless $block->{active};

	my $block_row = $self->data->search({issue_id => $i_id, story_id => $s_id, block_id => $b_id});
	$block_row->update({block_slug => $block->{slug}, last => \'NOW()'})
		if defined($block_delta->{slug});

	$block_row->update({captions => $self->_get_captions($block->{text}), last => \'NOW()'})
		if (defined($block_delta->{text}) and $self->_are_captions_updated($block_delta));
}

1;

package VNDRV::Connector::BarcoLNSPB;

use Moose;

use DB::BarcoLNSPBSchema;

extends 'VNDRV::Connector';

has 'db' => (is => 'ro', isa => 'Schema');
has 'data' => (is => 'ro', isa => 'HashRef', default => sub { {} });

sub BUILD {
	my $self = shift;

	my $db_config = $self->config->{db};
	my $addr = $db_config->{addr};
	my $user = $db_config->{user};
	my $pass = $db_config->{pass};
	my $db_name = $db_config->{db_name} // 'news_data';

	$self->{db} = DB::BarcoLNSPBSchema->connect("dbi:mysql:dbname=$db_name;host=$addr", $user, $pass, { mysql_enable_utf8 => 1 });

	my $tables = $self->config->{tables};
	for my $id (@$tables) {
		my $data = $self->{db}->resultset($id);
		$data->delete_all;
		$self->data->{$id} = $data;
	}
}

sub _get_time_field_value {
	my $self = shift;
	my $time = shift;
	return \"from_unixtime($time)";
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

	my $data = $self->data;
	for my $id (keys %$data) {
		$data->{$id}->search({issue_id => $i_id})->delete_all;
	}
}

sub _is_issue_air_falg_added {
	my $issue_data = shift;
	return (defined($issue_data->{type}) and $issue_data->{type}{new} eq 'active') ? 1 : 0;
}

sub _add_issue {
	my $self = shift;
	my $i_id = shift;

	my $issue = $self->get_issue({issue => $i_id});
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
	return defined($issue_data->{stories}) ? 1 : 0;
}

sub _update_issue_data {
	my $self = shift;
	my $i_id = shift;
	my $issue_delta = shift;

	my $issue = $self->get_issue({issue => $i_id});
	return
		unless _is_air_issue($issue);

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

	my $data = $self->data;
	for my $id (keys %$data) {
		$data->{$id}->search({issue_id => $i_id, story_id => $s_id})->delete_all;
	}
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
	return defined($story_data->{blocks}) ? 1 : 0;
}

sub _update_story_data {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $story_delta, $issue) =
		($params->{issue_id}, $params->{story_id}, $params->{story_delta}, $params->{issue});

	my $story = $issue->{stories}{$s_id};
	return
		unless $story->{active};

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
	my @captions = $self->_get_captions($block->{text});
	for my $caption (@captions) {
		$params->{caption} = $caption;
		$self->_add_caption($params);
	}
}

sub _process_block_changes {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $b_id, $block_delta, $issue) =
		($params->{issue_id}, $params->{story_id}, $params->{block_id}, $params->{block_delta}, $params->{issue});

	eval {
		if(!$block_delta or _is_block_active_flag_just_unset($block_delta)) {
			$self->_remove_block($i_id, $s_id, $b_id);
		} elsif(_is_block_active_flag_just_set($block_delta) or _is_significant_block_field_changed($block_delta)) {
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
	return defined($block_data->{text}) ? 1 : 0;
}

sub _remove_block {
	my $self = shift;
	my ($i_id, $s_id, $b_id) = @_;

	my $data = $self->data;
	for my $id (keys %$data) {
		$data->{$id}->search({issue_id => $i_id, story_id => $s_id, block_id => $b_id})->delete_all;
	}
}

sub _update_block_data {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $b_id, $issue) =
		($params->{issue_id}, $params->{story_id}, $params->{block_id}, $params->{issue});

	my $story = $issue->{stories}{$s_id};
	my $block = $story->{blocks}{$b_id};
	return
		unless $block->{active};

	my @captions = $self->_get_captions($block->{text});
	$self->_remove_old_captions($params, \@captions);
	for my $caption (@captions) {
		$params->{caption} = $caption;
		$self->_add_caption($params);
	}
}

sub _add_caption {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $b_id, $issue, $caption) =
		($params->{issue_id}, $params->{story_id}, $params->{block_id}, $params->{issue}, $params->{caption});

	my $template = $self->config->{templates}{$caption->{type}};
	return
		unless defined($template);

	my $table = $self->data->{$template->{table_id}};
	my $caption_exists = $table->find({
		issue_id => $i_id,
		story_id => $s_id,
		block_id => $b_id,
		caption_id => $caption->{md5}}, {key => 'path'}
	);
	return
		if $caption_exists;

	my %fields = (
		issue_id => $i_id,
		story_id => $s_id,
		block_id => $b_id,
		caption_id => $caption->{md5}
	);
	for my $field_id (keys %{$caption->{fields}}) {
		$fields{$template->{fields}{$field_id}} = $caption->{fields}{$field_id};
	}
	if(@{$template->{media_fields}}) {
		my $media_dir = $template->{media_dir} // $self->config->{dam}{media_dir};
		for my $field_id (@{$template->{media_fields}}) {
			my $media_id = $caption->{fields}{$field_id};
			my $file_name_with_ext = $self->_deliver_media($media_id, $media_dir);
			$fields{$template->{fields}{$field_id}} = $file_name_with_ext;
		}
	}
	$table->create(\%fields);
}

sub _remove_old_captions {
	my $self = shift;
	my $params = shift;
	my $captions = shift;

	my ($i_id, $s_id, $b_id) =
		($params->{issue_id}, $params->{story_id}, $params->{block_id});

	for my $table_id (@{$self->config->{tables}}) {
		my $table = $self->data->{$table_id};
		my @current_captions = $table->search({issue_id => $i_id, story_id => $s_id, block_id => $b_id}, 
			{columns => ['caption_id']}
		);
		for my $current_caption (@current_captions) {
			my $caption_id = $current_caption->caption_id;
			next
				if(grep {$_->{md5} eq $caption_id} @$captions);
			$table->search({
				issue_id => $i_id, story_id => $s_id, block_id => $b_id, caption_id => $caption_id
				})->delete_all;
		}
	}
}

override '_get_captions' => sub {
	my $self = shift;
	return map { $_->{md5} = $self->_get_caption_md5($_); $_ } super();
};

sub _deliver_media {
	my $self = shift;
	my $media_id = shift;
	my $media_dir = shift;

	my $dam_cfg = $self->config->{dam};
	my $req_result = $self->{ua}->get("$dam_cfg->{api_url}?query=read_clip_info&user=$dam_cfg->{user}&passwd=$dam_cfg->{password}&clip=$media_id");
	if(!$req_result->is_success) {
		$self->log->error("NUM0023E Can't call api: " . $req_result->status_line);
		return;
	}
	my $res = $req_result->decoded_content;
	if($res =~ /^ERROR\s+/) {
		$self->log->error("NUM0024E API call returned error: $res");
		return;
	}
	my $decoded_res;
	eval { $decoded_res = $self->json->decode($res) };
	if($@) {
		$self->log->error("NUM0025E API call returned invalid data: $res");
		return;
	}
	my $hrv_filename = $decoded_res->{clip}{FILE_V};
	(my $extension = $hrv_filename) =~ s/^.+\.(.+)$/$1/;
	(my $prefix = $media_id) =~ s/^(...).+$/$1/;
	my $name_with_ext = length($extension) ? "$media_id.$extension" : $media_id;
	my $full_name = "$media_dir/$name_with_ext";
	my $url = "$dam_cfg->{download_url}/$prefix/$media_id/$hrv_filename";
	system(qq|wget -c -N "$url" -O "$full_name" >/dev/null 2>&1 &|);
	return $name_with_ext;
}

1;
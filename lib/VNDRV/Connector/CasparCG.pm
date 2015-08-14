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
	my $dbname = $db_config->{name} // 'news_data';

	$self->{db} = DB::CGSchema->connect("dbi:Pg:dbname=$dbname;host=$addr", $user, $pass);
	$self->{data} = $self->{db}->resultset('Main');
	my $rundown_row = $self->data->find({issue_id => 0, story_id => 0, block_id => 0}, {key => 'path'});
	$self->data->create({issue_id => 0, story_id => 0, block_id => 0, last => \'NOW()'})
		unless $rundown_row;
}

sub _process_changes {
	my $self = shift;
	my $changes = shift;

	my $changed_issues = $changes->{issues};
	for my $i_id (keys %$changed_issues) {
		$self->_process_issue_change($i_id, $changed_issues->{$i_id});
	}
}

sub _process_issue_change {
	my $self = shift;
	my $i_id = shift;
	my $issue_delta = shift;

	eval {
		if(!$issue_delta or _is_air_flag_removed($issue_delta)) {
			$self->_remove_issue($i_id);
		} elsif(_is_air_falg_added($issue_delta)) {
			$self->_add_issue($i_id, $issue_delta);
		} elsif(_significant_field_changed($issue_delta)) {
			$self->_update_issue_data($i_id, $issue_delta);
		}
	};
	$self->log->error("NUD0020E Error while updating issue $i_id: $@");
}

sub _is_air_flag_removed {
	my $issue_data = shift;
	return (defined($issue_data->{type}) and $issue_data->{type}{new} ne 'active') ? 1 : 0;
}

sub _remove_issue {
	my $self = shift;
	my $i_id = shift;

	$self->data->search({issue_id => $i_id})->delete_all;
	$self->data->find({issue_id => 0, story_id => 0, block_id => 0}, {key => 'path'})->update({last => \'NOW()'});
}

sub _is_air_falg_added {
	my $issue_data = shift;
	return (defined($issue_data->{type}) and $issue_data->{type}{new} eq 'active') ? 1 : 0;
}

sub _add_issue {
	my $self = shift;
	my $i_id = shift;
	my $issue_data = shift;

	my $slug = defined($issue_data->{slug}) ? $issue_data->{slug}{new} : '';
	$self->data->update_or_create({issue_id => $i_id, issue_slug => $slug, story_id => 0, block_id => 0, last => \'NOW()'});
}

sub _significant_field_changed {
	my $issue_data = shift;
	return defined($issue_data->{slug}) ? 1 : 0;
}

sub _update_issue_data {
	my $self = shift;
	my $i_id = shift;
	my $issue_data = shift;

	$self->data->search({issue_id => $i_id})->update({issue_slug => $issue_data->{slug}{new}, last => \'NOW()'});
}

1;
